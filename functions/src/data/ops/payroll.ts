import { getFirestore, type DocumentData, type Query } from "firebase-admin/firestore";
import { denied, invalid, notFound } from "../../errors";
import type { Actor } from "../../auth/roles";
import type { SqlExecutor } from "../../db/executor";
import { calculatePayroll, type ApprovedLeaveRange, type CompensationVersion, type PayrollAttendanceSession, type ScheduleVersion } from "../../payroll/calculatePayroll";
import { requireRole } from "../authz";
import type { OperationRegistry } from "../operation";
import { reqId } from "../vars";
import { reqString } from "../../util/input";

type Row = Record<string, unknown>;
interface MemberRow extends Row {
  id: string;
  authUid: string;
  fullName: string;
  role: string;
  employeeCode?: string | null;
}
interface ScheduleRow extends Row {
  memberId: string;
  effectiveFrom: string | Date;
  effectiveTo: string | Date | null;
  dailyWorkHours: number | string;
  weeklyDayOff: number;
}
interface CompensationRow extends Row {
  memberId: string;
  effectiveFrom: string | Date;
  effectiveTo: string | Date | null;
  monthlySalary: number | string;
}
interface LeaveRow extends Row {
  applicantMemberId: string;
  startDate: string | Date;
  endDate: string | Date;
}

export const payrollOps: OperationRegistry = {
  GetMonthlyPayroll: async ({ db, actor }, vars) => {
    const month = reqString(vars, "month", 7, 7);
    if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
      throw invalid("month must use YYYY-MM format.");
    }
    const { monthStart, nextMonth } = monthBounds(month);
    const members = await payrollMembers(db, actor, vars);
    if (members.length === 0) {
      const settings = await getFirestore().collection("organization_settings")
        .doc(actor.organizationId!).get();
      const basis = settings.get("payCalculationBasis");
      return {
        month,
        basis: basis === "workdays" ? "workdays" : "hours",
        overtimeEnabled: settings.get("overtimeEnabled") === true,
        paySlips: [],
      };
    }

    const memberIds = members.map((member) => member.id);
    const [schedules, compensations, leaves] = await Promise.all([
      db.query<ScheduleRow>(
        `SELECT member_id AS "memberId", to_char(effective_from, 'YYYY-MM-DD') AS "effectiveFrom",
                CASE WHEN effective_to IS NULL THEN NULL ELSE to_char(effective_to, 'YYYY-MM-DD') END AS "effectiveTo",
                daily_work_hours AS "dailyWorkHours", weekly_day_off AS "weeklyDayOff"
           FROM employee_schedule_history
          WHERE member_id = ANY($1::text[]) AND effective_from < $3::date
            AND (effective_to IS NULL OR effective_to > $2::date)
          ORDER BY member_id, effective_from`,
        [memberIds, monthStart, nextMonth],
      ),
      db.query<CompensationRow>(
        `SELECT member_id AS "memberId", to_char(effective_from, 'YYYY-MM-DD') AS "effectiveFrom",
                CASE WHEN effective_to IS NULL THEN NULL ELSE to_char(effective_to, 'YYYY-MM-DD') END AS "effectiveTo",
                monthly_salary AS "monthlySalary"
           FROM employee_compensation_history
          WHERE member_id = ANY($1::text[]) AND effective_from < $3::date
            AND (effective_to IS NULL OR effective_to > $2::date)
          ORDER BY member_id, effective_from`,
        [memberIds, monthStart, nextMonth],
      ),
      db.query<LeaveRow>(
        `SELECT applicant_member_id AS "applicantMemberId",
                to_char(start_date, 'YYYY-MM-DD') AS "startDate",
                to_char(end_date, 'YYYY-MM-DD') AS "endDate"
           FROM leave_request
          WHERE organization_id = $1 AND status = 'approved'
            AND applicant_member_id = ANY($2::text[])
            AND end_date >= $3::date AND start_date < $4::date`,
        [actor.organizationId, memberIds, monthStart, nextMonth],
      ),
    ]);
    const attendance = await attendanceForScope(actor, members, monthStart, nextMonth);
    const settings = await getFirestore().collection("organization_settings")
      .doc(actor.organizationId!).get();
    const basis = settings.get("payCalculationBasis") === "workdays" ? "workdays" : "hours";
    const overtimeEnabled = settings.get("overtimeEnabled") === true;

    const paySlips = members.map((member) => {
      const memberAttendance = attendance.get(member.authUid) ?? [];
      const calculation = calculatePayroll({
        month,
        basis,
        overtimeEnabled,
        schedules: schedules.filter((row) => row.memberId === member.id).map(scheduleVersion),
        compensations: compensations.filter((row) => row.memberId === member.id).map(compensationVersion),
        attendance: memberAttendance,
        approvedLeaves: leaves
          .filter((row) => row.applicantMemberId === member.id)
          .map((row): ApprovedLeaveRange => ({ startDate: dateOnly(row.startDate), endDate: dateOnly(row.endDate) })),
      });
      return {
        memberId: member.id,
        fullName: member.fullName,
        role: member.role,
        employeeCode: member.employeeCode ?? null,
        calculation,
      };
    });
    return { month, basis, overtimeEnabled, paySlips };
  },
};

async function payrollMembers(db: SqlExecutor, actor: Actor, vars: Row): Promise<MemberRow[]> {
  const orgId = actor.organizationId;
  if (!orgId) throw denied("Organization context is required.");
  if (actor.role === "orgAdmin") {
    return db.query<MemberRow>(
      `SELECT id, auth_uid AS "authUid", full_name AS "fullName", role, employee_code AS "employeeCode"
         FROM organization_member
        WHERE organization_id = $1 AND (role IN ('employee', 'branchManager') OR auth_uid = $2)
        ORDER BY full_name`,
      [orgId, actor.uid],
    );
  }
  if (actor.role === "employee") {
    return db.query<MemberRow>(
      `SELECT id, auth_uid AS "authUid", full_name AS "fullName", role, employee_code AS "employeeCode"
         FROM organization_member WHERE organization_id = $1 AND auth_uid = $2`,
      [orgId, actor.uid],
    );
  }
  requireRole(actor, ["branchManager"]);
  const branchId = reqId(vars, "activeBranchId");
  if (!actor.branchIds.includes(branchId)) throw denied("Use an assigned active branch.");
  const branches = await db.query<{ status: string; organizationId: string }>(
    `SELECT status, organization_id AS "organizationId" FROM branch WHERE id = $1`,
    [branchId],
  );
  if (!branches[0] || branches[0].status !== "active" || branches[0].organizationId !== orgId) {
    throw notFound("Branch not found.");
  }
  return db.query<MemberRow>(
    `SELECT id, auth_uid AS "authUid", full_name AS "fullName", role, employee_code AS "employeeCode"
       FROM organization_member
      WHERE organization_id = $1 AND auth_uid = $2
     UNION
     SELECT m.id, m.auth_uid AS "authUid", m.full_name AS "fullName", m.role, m.employee_code AS "employeeCode"
       FROM organization_member m JOIN user_branch_assignment a ON a.member_id = m.id
      WHERE m.organization_id = $1 AND m.role = 'employee' AND a.branch_id = $3
      ORDER BY "fullName"`,
    [orgId, actor.uid, branchId],
  );
}

async function attendanceForScope(
  actor: Actor,
  members: MemberRow[],
  monthStart: string,
  nextMonth: string,
): Promise<Map<string, PayrollAttendanceSession[]>> {
  const collection = getFirestore().collection("attendance_entries");
  const base = collection
    .where("organizationId", "==", actor.organizationId)
    .where("workDateString", ">=", monthStart)
    .where("workDateString", "<", nextMonth);
  let queries: Query<DocumentData>[];
  if (actor.role === "employee") {
    queries = [base.where("employeeId", "==", actor.uid)];
  } else if (actor.role === "branchManager") {
    const ids = members.map((member) => member.authUid);
    const chunks: string[][] = [];
    for (let index = 0; index < ids.length; index += 30) {
      chunks.push(ids.slice(index, index + 30));
    }
    queries = chunks.map((chunk) => base.where("employeeId", "in", chunk));
  } else {
    queries = [base];
  }
  const snapshots = await Promise.all(queries.map((query) => query.get()));
  const uidSet = new Set(members.map((member) => member.authUid));
  const byUid = new Map<string, PayrollAttendanceSession[]>();
  const seen = new Set<string>();
  for (const snapshot of snapshots) {
    for (const document of snapshot.docs) {
      if (seen.has(document.id)) continue;
      seen.add(document.id);
      const data = document.data();
      const uid = typeof data.employeeId === "string" ? data.employeeId : "";
      if (!uidSet.has(uid)) continue;
      const workDate = typeof data.workDateString === "string" ? data.workDateString : "";
      const checkInAt = timestampDate(data.checkInAt);
      const checkOutAt = timestampDate(data.checkOutAt);
      const breaks = Array.isArray(data.breaks) ? data.breaks.flatMap((item) => {
        if (typeof item !== "object" || item === null) return [];
        const value = item as Record<string, unknown>;
        const startAt = timestampDate(value.startAt);
        return startAt ? [{ startAt, endAt: timestampDate(value.endAt) }] : [];
      }) : [];
      const record: PayrollAttendanceSession = { workDate, checkInAt, checkOutAt, breaks, status: typeof data.status === "string" ? data.status : undefined };
      const items = byUid.get(uid) ?? [];
      items.push(record);
      byUid.set(uid, items);
    }
  }
  return byUid;
}

function timestampDate(value: unknown): Date | undefined {
  if (value instanceof Date) return value;
  if (typeof value === "object" && value !== null && "toDate" in value) {
    const toDate = (value as { toDate?: unknown }).toDate;
    if (typeof toDate === "function") {
      const date = toDate.call(value);
      if (date instanceof Date && Number.isFinite(date.getTime())) return date;
    }
  }
  return undefined;
}

function scheduleVersion(row: ScheduleRow): ScheduleVersion {
  return {
    effectiveFrom: dateOnly(row.effectiveFrom),
    effectiveTo: row.effectiveTo ? dateOnly(row.effectiveTo) : null,
    dailyWorkHours: Number(row.dailyWorkHours),
    weeklyDayOff: Number(row.weeklyDayOff),
  };
}

function compensationVersion(row: CompensationRow): CompensationVersion {
  return {
    effectiveFrom: dateOnly(row.effectiveFrom),
    effectiveTo: row.effectiveTo ? dateOnly(row.effectiveTo) : null,
    monthlySalary: Number(row.monthlySalary),
  };
}

function dateOnly(value: string | Date): string {
  return value instanceof Date ? value.toISOString().slice(0, 10) : value.slice(0, 10);
}

function monthBounds(month: string): { monthStart: string; nextMonth: string } {
  const [year, monthNumber] = month.split("-").map(Number);
  const next = new Date(Date.UTC(year, monthNumber, 1));
  return {
    monthStart: `${month}-01`,
    nextMonth: `${next.getUTCFullYear()}-${String(next.getUTCMonth() + 1).padStart(2, "0")}-01`,
  };
}
