import { getFirestore } from "firebase-admin/firestore";
import type { SqlExecutor } from "../db/executor";
import type {
  AccrualVersion,
  LedgerInput,
  LedgerLeave,
  LedgerSchedule,
  LeaveTypePolicy,
} from "../payroll/leaveLedger";

/** An organization's leave types (archived ones included) and accrual history. */
export interface LeavePolicy {
  types: LeaveTypePolicy[];
  accrual: AccrualVersion[];
}

export async function loadLeavePolicy(db: SqlExecutor, organizationId: string): Promise<LeavePolicy> {
  const [types, allowances, accrual] = await Promise.all([
    db.query<{ id: string; paid: boolean }>(
      `SELECT id, paid FROM leave_type WHERE organization_id = $1`,
      [organizationId],
    ),
    db.query<{ leaveTypeId: string; effectiveFrom: string; yearlyDays: number; carryForward: boolean }>(
      `SELECT a.leave_type_id AS "leaveTypeId",
              to_char(a.effective_from, 'YYYY-MM-DD') AS "effectiveFrom",
              a.yearly_days AS "yearlyDays", a.carry_forward AS "carryForward"
         FROM leave_type_allowance a JOIN leave_type t ON t.id = a.leave_type_id
        WHERE t.organization_id = $1`,
      [organizationId],
    ),
    db.query<{ effectiveFrom: string; monthlyAccrual: boolean }>(
      `SELECT to_char(effective_from, 'YYYY-MM-DD') AS "effectiveFrom",
              monthly_accrual AS "monthlyAccrual"
         FROM organization_leave_policy WHERE organization_id = $1`,
      [organizationId],
    ),
  ]);
  return {
    types: types.map((type) => ({
      id: type.id,
      paid: type.paid,
      allowances: allowances
        .filter((a) => a.leaveTypeId === type.id)
        .map((a) => ({
          effectiveFrom: a.effectiveFrom,
          yearlyDays: Number(a.yearlyDays),
          carryForward: a.carryForward,
        })),
    })),
    accrual: accrual.map((a) => ({ effectiveFrom: a.effectiveFrom, monthlyAccrual: a.monthlyAccrual })),
  };
}

/** Full schedule history and approved leave (through [until]) per member. */
export async function loadLeaveHistory(
  db: SqlExecutor,
  organizationId: string,
  memberIds: readonly string[],
  until: string,
): Promise<Map<string, { schedules: LedgerSchedule[]; leaves: LedgerLeave[] }>> {
  const history = new Map<string, { schedules: LedgerSchedule[]; leaves: LedgerLeave[] }>();
  for (const id of memberIds) history.set(id, { schedules: [], leaves: [] });
  if (memberIds.length === 0) return history;
  const [schedules, leaves] = await Promise.all([
    db.query<{ memberId: string } & LedgerSchedule>(
      `SELECT member_id AS "memberId", to_char(effective_from, 'YYYY-MM-DD') AS "effectiveFrom",
              CASE WHEN effective_to IS NULL THEN NULL
                   ELSE to_char(effective_to, 'YYYY-MM-DD') END AS "effectiveTo",
              weekly_day_off AS "weeklyDayOff"
         FROM employee_schedule_history
        WHERE member_id = ANY($1::text[]) AND effective_from <= $2::date`,
      [memberIds, until],
    ),
    db.query<{ memberId: string } & LedgerLeave>(
      `SELECT applicant_member_id AS "memberId", id, leave_type_id AS "leaveTypeId",
              to_char(start_date, 'YYYY-MM-DD') AS "startDate",
              to_char(end_date, 'YYYY-MM-DD') AS "endDate"
         FROM leave_request
        WHERE organization_id = $1 AND status = 'approved'
          AND applicant_member_id = ANY($2::text[]) AND start_date <= $3::date`,
      [organizationId, memberIds, until],
    ),
  ]);
  for (const { memberId, ...schedule } of schedules) {
    history.get(memberId)?.schedules.push({ ...schedule, weeklyDayOff: Number(schedule.weeklyDayOff) });
  }
  for (const { memberId, ...leave } of leaves) history.get(memberId)?.leaves.push(leave);
  return history;
}

export interface EmploymentDates {
  joiningDate?: string;
  relievingDate?: string;
}

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

/** Joining and relieving dates from the users/{uid} profiles (by auth uid). */
export async function loadEmploymentDates(
  authUids: readonly string[],
): Promise<Map<string, EmploymentDates>> {
  const dates = new Map<string, EmploymentDates>();
  const uids = [...new Set(authUids.filter(Boolean))];
  if (uids.length === 0) return dates;
  const firestore = getFirestore();
  const snapshots = await firestore.getAll(...uids.map((uid) => firestore.collection("users").doc(uid)));
  for (const snapshot of snapshots) {
    const joining = snapshot.get("joiningDate");
    const relieving = snapshot.get("relievingDate");
    dates.set(snapshot.id, {
      joiningDate: typeof joining === "string" && ISO_DATE.test(joining) ? joining : undefined,
      relievingDate: typeof relieving === "string" && ISO_DATE.test(relieving) ? relieving : undefined,
    });
  }
  return dates;
}

/** Ledger input for one member. */
export function ledgerInput(
  policy: LeavePolicy,
  history: { schedules: LedgerSchedule[]; leaves: LedgerLeave[] } | undefined,
  employment: EmploymentDates | undefined,
): LedgerInput {
  return {
    types: policy.types,
    accrual: policy.accrual,
    schedules: history?.schedules ?? [],
    leaves: history?.leaves ?? [],
    joiningDate: employment?.joiningDate,
    relievingDate: employment?.relievingDate,
  };
}
