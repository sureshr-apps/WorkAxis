import {
  FieldValue,
  Timestamp,
  type DocumentData,
  type Firestore,
  type Transaction,
} from "firebase-admin/firestore";
import type { SqlExecutor } from "../db/executor";
import { weeklyDaysOffFrom } from "../util/weeklyDaysOff";
import { potentialOvertimeBySession, type ClosedSession, type TimedBreak } from "./overtime";
import type { SessionDeadlines, AttendanceTiming } from "./sessionPolicy";
import { addDays, type ScheduleSpan, type ShiftWindow } from "./shiftWindow";

export const ENTRIES = "attendance_entries";
/** One document per employee while a session is open: `attendance_session_state/{uid}`. */
export const SESSION_STATE = "attendance_session_state";
export const CORRECTIONS = "attendance_corrections";

/** Schedule versions of [memberId] in force anywhere from the day before [date] to the day after. */
export async function loadScheduleSpans(
  db: SqlExecutor,
  memberId: string,
  date: string,
): Promise<ScheduleSpan[]> {
  const rows = await db.query<{
    effectiveFrom: string;
    effectiveTo: string | null;
    shiftHours: string;
    dailyWorkHours: number | string;
    weeklyDaysOff: number[];
  }>(
    `SELECT to_char(effective_from, 'YYYY-MM-DD') AS "effectiveFrom",
            CASE WHEN effective_to IS NULL THEN NULL
                 ELSE to_char(effective_to, 'YYYY-MM-DD') END AS "effectiveTo",
            shift_hours AS "shiftHours", daily_work_hours AS "dailyWorkHours",
            weekly_days_off AS "weeklyDaysOff"
       FROM employee_schedule_history
      WHERE member_id = $1 AND effective_from <= $3::date
        AND (effective_to IS NULL OR effective_to > $2::date)`,
    [memberId, addDays(date, -1), addDays(date, 1)],
  );
  return rows.map((row) => ({
    effectiveFrom: row.effectiveFrom,
    effectiveTo: row.effectiveTo,
    shiftHours: row.shiftHours,
    dailyWorkHours: Number(row.dailyWorkHours),
    weeklyDaysOff: weeklyDaysOffFrom(row.weeklyDaysOff),
  }));
}

/** Entry fields describing the scheduled shift and the open session's deadlines. */
export function shiftFields(window: ShiftWindow | null, deadlines: SessionDeadlines): DocumentData {
  const stamp = (value: Date | null) => (value ? Timestamp.fromDate(value) : null);
  return {
    scheduledStartAt: stamp(window?.startAt ?? null),
    scheduledEndAt: stamp(window?.endAt ?? null),
    scheduledHours: window?.scheduledHours ?? null,
    checkoutReminderAt: stamp(deadlines.reminderAt),
    checkoutOverdueAt: stamp(deadlines.overdueAt),
    sessionExpiresAt: stamp(deadlines.expiresAt),
    checkoutStatus: "none",
    open: true,
    overtimeStatus: "none",
    potentialOvertimeHours: 0,
  };
}

/** The per-employee open-session document the sweep uses. */
export function sessionStateData(input: {
  employeeId: string;
  organizationId: string;
  branchId: string;
  entryId: string;
  workDate: string;
  checkInAt: Date;
  deadlines: SessionDeadlines;
}): DocumentData {
  return {
    employeeId: input.employeeId,
    organizationId: input.organizationId,
    branchId: input.branchId,
    activeEntryId: input.entryId,
    workDateString: input.workDate,
    checkInAt: Timestamp.fromDate(input.checkInAt),
    checkoutOverdueAt: input.deadlines.overdueAt ? Timestamp.fromDate(input.deadlines.overdueAt) : null,
    // Sessions without an overdue time never need the overdue flag.
    overdueFlagged: input.deadlines.overdueAt === null,
    sessionExpiresAt: Timestamp.fromDate(input.deadlines.expiresAt),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function entryBreaks(data: DocumentData | undefined): TimedBreak[] {
  const stored = Array.isArray(data?.breaks) ? data!.breaks : [];
  return stored.flatMap((item: unknown) => {
    const value = item as { startAt?: unknown; endAt?: unknown };
    return value?.startAt instanceof Timestamp
      ? [{
          startAt: value.startAt.toDate(),
          endAt: value.endAt instanceof Timestamp ? value.endAt.toDate() : null,
        }]
      : [];
  });
}

/**
 * Recomputes the potential overtime of every closed session of one employee's
 * shift date and writes it. [pending] supplies a check-out being written in
 * the same transaction. Approved hours never exceed the new potential, and a
 * session without overtime returns to "none". All reads happen before writes.
 */
export async function recomputeDayOvertime(
  firestore: Firestore,
  tx: Transaction,
  employeeId: string,
  organizationId: string,
  workDate: string,
  pending: { id: string; checkOutAt: Date; extra?: DocumentData },
): Promise<void> {
  const snapshot = await tx.get(
    firestore.collection(ENTRIES)
      .where("organizationId", "==", organizationId)
      .where("employeeId", "==", employeeId)
      .where("workDateString", "==", workDate),
  );
  const sessions: ClosedSession[] = [];
  let scheduledHours: number | null = null;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (typeof data.scheduledHours === "number") scheduledHours ??= data.scheduledHours;
    const checkInAt = data.checkInAt instanceof Timestamp ? data.checkInAt.toDate() : null;
    const checkOutAt = doc.id === pending.id
      ? pending.checkOutAt
      : data.checkOutAt instanceof Timestamp ? data.checkOutAt.toDate() : null;
    if (checkInAt && checkOutAt) {
      sessions.push({ id: doc.id, checkInAt, checkOutAt, breaks: entryBreaks(data) });
    }
  }
  // Overtime applies only to scheduled shifts.
  const potential = scheduledHours === null
    ? new Map<string, number>()
    : potentialOvertimeBySession(sessions, scheduledHours);
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const hours = potential.get(doc.id) ?? 0;
    const update: DocumentData = doc.id === pending.id ? { ...(pending.extra ?? {}) } : {};
    update.potentialOvertimeHours = hours;
    const status = typeof data.overtimeStatus === "string" ? data.overtimeStatus : "none";
    if (hours <= 0) {
      update.overtimeStatus = "none";
      update.approvedOvertimeHours = FieldValue.delete();
    } else if (status === "none") {
      update.overtimeStatus = "pending";
    } else if (status === "approved" && Number(data.approvedOvertimeHours) > hours) {
      update.approvedOvertimeHours = hours;
    }
    if (doc.id === pending.id || hours !== data.potentialOvertimeHours ||
        update.overtimeStatus !== undefined || update.approvedOvertimeHours !== undefined) {
      tx.update(doc.ref, update);
    }
  }
}

export type { AttendanceTiming };
