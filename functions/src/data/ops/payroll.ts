import { getFirestore, type DocumentData, type Query } from "firebase-admin/firestore";
import { denied, invalid, notFound } from "../../errors";
import type { Actor } from "../../auth/roles";
import type { SqlExecutor } from "../../db/executor";
import { loadEmploymentDates, loadLeaveHistory, loadLeavePolicy, ledgerInput } from "../../leave/leavePolicyStore";
import { leaveLedger } from "../../payroll/leaveLedger";
import { calculatePayroll, type PayrollLeaveDay, type CompensationVersion, type PayrollAttendanceSession, type PayrollCalculation, type ScheduleVersion } from "../../payroll/calculatePayroll";
import { findActiveBranch, requireActiveBranch, requireRole } from "../authz";
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
interface PayrollSummaryRow {
  employeeCount: number;
  availableCount: number;
  scheduledHours: number;
  payableHours: number;
  actualHours: number;
  scheduledWorkdays: number;
  payableWorkdays: number;
  paidLeaveDays: number;
  unpaidLeaveDays: number;
  unpaidLeaveImpact: number;
  overtimeHours: number;
  overtimePay: number;
  basePay: number;
  grossPay: number;
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
export const payrollOps: OperationRegistry = {
  GetMonthlyPayroll: async ({ db, actor }, vars) => {
    const month = reqString(vars, "month", 7, 7);
    if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
      throw invalid("month must use YYYY-MM format.");
    }
    const { monthStart, nextMonth } = monthBounds(month);
    const view = typeof vars.view === "string" ? vars.view : "self";
    if (!["self", "employee", "branchSummary", "organizationSummary"].includes(view)) {
      throw invalid("Unknown payslip view.");
    }
    let members = await payrollMembers(db, actor, vars);
    if (view === "self") {
      members = members.filter((member) => member.authUid === actor.uid);
    } else if (view === "employee") {
      if (actor.role !== "orgAdmin" && actor.role !== "branchManager") throw denied();
      const selectedId = reqId(vars, "selectedMemberId");
      const selected = members.find((member) => member.id === selectedId && member.role === "employee");
      if (!selected) throw denied("Employee payslip is outside your authorized scope.");
      members = [selected];
    } else if (view === "branchSummary") {
      if (actor.role !== "branchManager") throw denied();
      members = members.filter((member) => member.role === "employee");
    } else {
      if (actor.role !== "orgAdmin") throw denied();
      members = members.filter((member) => member.role === "employee");
    }
    const isSummaryView =
      view === "branchSummary" || view === "organizationSummary";
    if (members.length === 0) {
      const settings = await getFirestore().collection("organization_settings")
        .doc(actor.organizationId!).get();
      const basis = settings.get("payCalculationBasis");
      let branchSummaries: (PayrollSummaryRow & { branchId: string; branchName: string })[] = [];
      if (view === "branchSummary") {
        const branch = await findActiveBranch(
          db,
          reqId(vars, "activeBranchId"),
          actor.organizationId,
        );
        branchSummaries = (branch ? [branch] : []).map((branch) => ({
          branchId: branch.id,
          branchName: branch.name,
          ...emptySummary(),
        }));
      } else if (view === "organizationSummary") {
        const branches = await db.query<{ id: string; name: string }>(
          `SELECT id, name FROM branch
            WHERE organization_id = $1 AND status = 'active'
            ORDER BY name`,
          [actor.organizationId],
        );
        branchSummaries = branches.map((branch) => ({
          branchId: branch.id,
          branchName: branch.name,
          ...emptySummary(),
        }));
      }
      return {
        month,
        basis: basis === "workdays" ? "workdays" : "hours",
        overtimeEnabled: settings.get("overtimeEnabled") === true,
        paySlips: [],
        summary: isSummaryView ? emptySummary() : null,
        branchSummaries,
      };
    }

    const memberIds = members.map((member) => member.id);
    const [schedules, compensations] = await Promise.all([
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
    ]);
    // Whether each approved leave day is paid depends on the whole leave
    // history (allowance used earlier in the year, carry-forward), so the
    // ledger reads it up to the end of this month.
    const monthEnd = lastDayOf(month);
    const [policy, leaveHistory, employment] = await Promise.all([
      loadLeavePolicy(db, actor.organizationId!),
      loadLeaveHistory(db, actor.organizationId!, memberIds, monthEnd),
      loadEmploymentDates(members.map((member) => member.authUid)),
    ]);
    const attendance = await attendanceForScope(actor, members, monthStart, nextMonth);
    const settings = await getFirestore().collection("organization_settings")
      .doc(actor.organizationId!).get();
    const basis = settings.get("payCalculationBasis") === "workdays" ? "workdays" : "hours";
    const overtimeEnabled = settings.get("overtimeEnabled") === true;

    const paySlips = members.map((member) => {
      const memberAttendance = attendance.get(member.authUid) ?? [];
      const dates = employment.get(member.authUid);
      const leaveDays = leaveLedger(ledgerInput(policy, leaveHistory.get(member.id), dates))
        .filter((day) => day.date >= monthStart && day.date <= monthEnd)
        .map((day): PayrollLeaveDay => ({ date: day.date, paid: day.paid }));
      const calculation = calculatePayroll({
        month,
        basis,
        overtimeEnabled,
        schedules: schedules.filter((row) => row.memberId === member.id).map(scheduleVersion),
        compensations: compensations.filter((row) => row.memberId === member.id).map(compensationVersion),
        attendance: memberAttendance,
        leaveDays,
        employmentStart: dates?.joiningDate,
        employmentEnd: dates?.relievingDate,
      });
      return {
        memberId: member.id,
        authUid: member.authUid,
        fullName: member.fullName,
        role: member.role,
        employeeCode: member.employeeCode ?? null,
        calculation,
      };
    });
    if (view === "branchSummary") {
      const branchId = reqId(vars, "activeBranchId");
      const branch = await findActiveBranch(db, branchId, actor.organizationId);
      const assignments = await db.query<{ memberId: string; branchCount: number }>(
        `SELECT a.member_id AS "memberId", count(*)::int AS "branchCount"
           FROM user_branch_assignment a
           JOIN branch b ON b.id = a.branch_id
          WHERE b.organization_id = $1 AND b.status = 'active'
            AND a.member_id = ANY($2::text[])
          GROUP BY a.member_id`,
        [actor.organizationId, memberIds],
      );
      const branchCountByMember = new Map(
        assignments.map((row) => [row.memberId, row.branchCount]),
      );
      const allocatedSlips = paySlips.map((slip) => ({
        ...slip,
        calculation: scaleCalculation(
          slip.calculation,
          1 / Math.max(1, branchCountByMember.get(slip.memberId) ?? 1),
        ),
      }));
      const summary = sumCalculations(allocatedSlips);
      return {
        month,
        basis,
        overtimeEnabled,
        paySlips: [],
        summary,
        branchSummaries: branch ? [{ branchId, branchName: branch.name, ...summary }] : [],
      };
    }
    if (view === "organizationSummary") {
      const branches = await db.query<{ id: string; name: string }>(
        `SELECT id, name FROM branch
          WHERE organization_id = $1 AND status = 'active'
          ORDER BY name`,
        [actor.organizationId],
      );
      const assignments = await db.query<{ memberId: string; branchId: string; branchName: string }>(
        `SELECT a.member_id AS "memberId", a.branch_id AS "branchId", b.name AS "branchName"
           FROM user_branch_assignment a
           JOIN branch b ON b.id = a.branch_id
          WHERE b.organization_id = $1 AND b.status = 'active'
            AND a.member_id = ANY($2::text[])
          ORDER BY b.name, a.member_id`,
        [actor.organizationId, memberIds],
      );
      const memberBranches = new Map<string, { branchId: string; branchName: string }[]>();
      for (const assignment of assignments) {
        const list = memberBranches.get(assignment.memberId) ?? [];
        list.push({ branchId: assignment.branchId, branchName: assignment.branchName });
        memberBranches.set(assignment.memberId, list);
      }
      const groups = new Map<string, { branchId: string; branchName: string; rows: typeof paySlips }>(
        branches.map((branch) => [branch.id, {
          branchId: branch.id,
          branchName: branch.name,
          rows: [],
        }]),
      );
      for (const slip of paySlips) {
        const branches = memberBranches.get(slip.memberId) ?? [];
        if (branches.length === 0) continue;
        const share = 1 / branches.length;
        for (const branch of branches) {
          const group = groups.get(branch.branchId) ?? { ...branch, rows: [] };
          group.rows.push({ ...slip, calculation: scaleCalculation(slip.calculation, share) });
          groups.set(branch.branchId, group);
        }
      }
      return {
        month,
        basis,
        overtimeEnabled,
        paySlips: [],
        summary: sumCalculations(paySlips),
        branchSummaries: [...groups.values()].map((group) => ({
          branchId: group.branchId,
          branchName: group.branchName,
          ...sumCalculations(group.rows),
        })),
      };
    }
    return { month, basis, overtimeEnabled, paySlips, summary: null, branchSummaries: [] };
  },
};

function emptySummary(): PayrollSummaryRow {
  return {
    employeeCount: 0, availableCount: 0, scheduledHours: 0, payableHours: 0,
    actualHours: 0, scheduledWorkdays: 0, payableWorkdays: 0, paidLeaveDays: 0, unpaidLeaveDays: 0,
    unpaidLeaveImpact: 0, overtimeHours: 0, overtimePay: 0, basePay: 0, grossPay: 0,
  };
}

function sumCalculations(rows: readonly { calculation: PayrollCalculation }[]): PayrollSummaryRow {
  const summary = emptySummary();
  summary.employeeCount = rows.length;
  for (const { calculation } of rows) {
    if (calculation.available === true) summary.availableCount++;
    for (const key of ["scheduledHours", "payableHours", "actualHours", "scheduledWorkdays", "payableWorkdays", "paidLeaveDays", "unpaidLeaveDays", "unpaidLeaveImpact", "overtimeHours", "overtimePay", "basePay", "grossPay"] as const) {
      summary[key] += calculation[key];
    }
  }
  return summary;
}

function scaleCalculation(calculation: PayrollCalculation, share: number): PayrollCalculation {
  const scale = (value: number) => Math.round(value * share * 100) / 100;
  return {
    ...calculation,
    scheduledHours: scale(calculation.scheduledHours),
    payableHours: scale(calculation.payableHours),
    actualHours: scale(calculation.actualHours),
    scheduledWorkdays: scale(calculation.scheduledWorkdays),
    payableWorkdays: scale(calculation.payableWorkdays),
    paidLeaveDays: scale(calculation.paidLeaveDays),
    unpaidLeaveDays: scale(calculation.unpaidLeaveDays),
    unpaidLeaveImpact: scale(calculation.unpaidLeaveImpact),
    overtimeHours: scale(calculation.overtimeHours),
    overtimePay: scale(calculation.overtimePay),
    basePay: scale(calculation.basePay),
    grossPay: scale(calculation.grossPay),
  };
}

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
  await requireActiveBranch(db, branchId, orgId, () => notFound("Branch not found."));
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

/** Last calendar day of a `YYYY-MM` month. */
function lastDayOf(month: string): string {
  const [year, monthNumber] = month.split("-").map(Number);
  const last = new Date(Date.UTC(year, monthNumber, 0));
  return last.toISOString().slice(0, 10);
}

function monthBounds(month: string): { monthStart: string; nextMonth: string } {
  const [year, monthNumber] = month.split("-").map(Number);
  const next = new Date(Date.UTC(year, monthNumber, 1));
  return {
    monthStart: `${month}-01`,
    nextMonth: `${next.getUTCFullYear()}-${String(next.getUTCMonth() + 1).padStart(2, "0")}-01`,
  };
}
