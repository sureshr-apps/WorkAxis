import { denied, invalid, notFound, precondition } from "../../errors";
import type { Actor } from "../../auth/roles";
import { requireRole } from "../authz";
import type { OperationRegistry } from "../operation";
import { parseDate, reqDate, reqId } from "../vars";
import { reqNumber, reqString } from "../../util/input";
import { parseWeeklyDaysOff, weeklyDaysOffFrom } from "../../util/weeklyDaysOff";
import { parseShiftHours } from "../../attendance/shiftWindow";
import { selectOne } from "../sql";

type Row = Record<string, unknown>;
type HistoryKind = "schedule" | "compensation";
interface MemberScope {
  id: string;
  authUid: string;
  fullName: string;
  role: string;
  organizationId: string;
}
interface HistoryRow {
  id: string;
  effectiveFrom: string | Date;
  effectiveTo: string | Date | null;
  dailyWorkHours?: number | string;
  shiftHours?: string;
  weeklyDaysOff?: number[] | null;
  monthlySalary?: number | string;
}

export const workforceOps: OperationRegistry = {
  GetEmployeeWorkforceHistory: async ({ db, actor }, vars) => {
    const member = await memberInScope(db, actor, vars);
    const [schedules, compensations] = await Promise.all([
      db.query<HistoryRow>(
        `SELECT id, effective_from AS "effectiveFrom", effective_to AS "effectiveTo",
                daily_work_hours AS "dailyWorkHours", shift_hours AS "shiftHours",
                weekly_days_off AS "weeklyDaysOff"
           FROM employee_schedule_history WHERE member_id = $1
          ORDER BY effective_from DESC`,
        [member.id],
      ),
      db.query<HistoryRow>(
        `SELECT id, effective_from AS "effectiveFrom", effective_to AS "effectiveTo",
                monthly_salary AS "monthlySalary"
           FROM employee_compensation_history WHERE member_id = $1
          ORDER BY effective_from DESC`,
        [member.id],
      ),
    ]);
    return {
      member: { id: member.id, fullName: member.fullName, role: member.role },
      schedules: schedules.map(scheduleDto),
      compensations: compensations.map(compensationDto),
    };
  },

  SaveEmployeeSchedule: async ({ db, actor }, vars) => {
    requireRole(actor, ["orgAdmin", "branchManager"]);
    const member = await memberInScope(db, actor, vars, true);
    const effectiveFrom = reqDate(vars, "effectiveFrom");
    requireTodayOrFuture(effectiveFrom);
    const dailyWorkHours = reqNumber(vars, "dailyWorkHours", 0.5, 24);
    const shiftHours = reqString(vars, "shiftHours", 1, 100).trim();
    const weeklyDaysOff = parseWeeklyDaysOff(vars);
    if (!weeklyDaysOff) throw invalid("weeklyDaysOff is required (an empty list means no day off).");
    const shiftDuration = parseShiftDurationHours(shiftHours);
    if (Math.abs(shiftDuration - dailyWorkHours) > 0.01) {
      throw invalid("Daily work hours must match the shift window.");
    }
    await db.transaction(async (tx) => {
      await lockMember(tx, member.id);
      await insertEffectiveVersion(tx, member.id, "schedule", effectiveFrom, actor.uid, {
        dailyWorkHours,
        shiftHours,
        weeklyDaysOff,
      });
    });
    return { saved: true };
  },

  SaveEmployeeCompensation: async ({ db, actor }, vars) => {
    requireRole(actor, ["orgAdmin", "branchManager"]);
    const member = await memberInScope(db, actor, vars, true);
    const effectiveFrom = reqDate(vars, "effectiveFrom");
    requireTodayOrFuture(effectiveFrom);
    const monthlySalary = reqNumber(vars, "monthlySalary", 0, 100_000_000);
    await db.transaction(async (tx) => {
      await lockMember(tx, member.id);
      await insertEffectiveVersion(tx, member.id, "compensation", effectiveFrom, actor.uid, {
        monthlySalary,
      });
    });
    return { saved: true };
  },
};

async function memberInScope(
  db: Parameters<OperationRegistry[string]>[0]["db"],
  actor: Actor,
  vars: Row,
  forEdit = false,
): Promise<MemberScope> {
  const memberId = typeof vars.memberId === "string" && vars.memberId.trim()
    ? reqId(vars, "memberId")
    : null;
  const member = memberId
    ? await selectOne<MemberScope>(
        db,
        `SELECT id, auth_uid AS "authUid", full_name AS "fullName", role,
                organization_id AS "organizationId"
           FROM organization_member WHERE id = $1`,
        [memberId],
      )
    : await selectOne<MemberScope>(
        db,
        `SELECT id, auth_uid AS "authUid", full_name AS "fullName", role,
                organization_id AS "organizationId"
           FROM organization_member WHERE auth_uid = $1 AND organization_id = $2`,
        [actor.uid, actor.organizationId],
      );
  if (!member || !member.organizationId || member.organizationId !== actor.organizationId) {
    throw notFound("Employee not found.");
  }
  if (actor.role === "orgAdmin") {
    if (forEdit && member.authUid === actor.uid) throw denied("You cannot edit your own workforce record.");
    return member;
  }
  if (member.authUid === actor.uid && actor.role === "branchManager") {
    if (forEdit) throw denied("You cannot edit your own workforce record.");
    return member;
  }
  if (actor.role === "employee") {
    if (member.authUid !== actor.uid || forEdit) throw denied();
    return member;
  }
  if (actor.role !== "branchManager") throw denied();

  const activeBranchId = reqId(vars, "activeBranchId");
  if (!actor.branchIds.includes(activeBranchId)) throw denied("Use an assigned active branch.");
  const assignment = await selectOne<{ status: string }>(
    db,
    `SELECT b.status FROM user_branch_assignment a JOIN branch b ON b.id = a.branch_id
      WHERE a.member_id = $1 AND a.branch_id = $2 AND b.organization_id = $3`,
    [member.id, activeBranchId, actor.organizationId],
  );
  if (!assignment || assignment.status !== "active") throw notFound("Employee not found.");
  if (member.role !== "employee" && !(!forEdit && member.authUid === actor.uid)) {
    throw denied("Branch Managers may manage employees only.");
  }
  return member;
}

async function lockMember(
  tx: Parameters<OperationRegistry[string]>[0]["db"],
  memberId: string,
): Promise<void> {
  const rows = await tx.query(`SELECT id FROM organization_member WHERE id = $1 FOR UPDATE`, [memberId]);
  if (rows.length === 0) throw notFound("Employee not found.");
}

async function insertEffectiveVersion(
  tx: Parameters<OperationRegistry[string]>[0]["db"],
  memberId: string,
  kind: HistoryKind,
  effectiveFrom: string,
  actorUid: string,
  values: {
    dailyWorkHours?: number;
    shiftHours?: string;
    weeklyDaysOff?: number[];
    monthlySalary?: number;
  },
): Promise<void> {
  const table = kind === "schedule" ? "employee_schedule_history" : "employee_compensation_history";
  const rows = await tx.query<HistoryRow>(
    `SELECT id, effective_from AS "effectiveFrom", effective_to AS "effectiveTo"
       FROM ${table} WHERE member_id = $1 ORDER BY effective_from FOR UPDATE`,
    [memberId],
  );
  const same = rows.find((row) => dateOnly(row.effectiveFrom) === effectiveFrom);
  if (same) {
    if (kind === "schedule") {
      await tx.query(
        `UPDATE employee_schedule_history SET daily_work_hours = $2, shift_hours = $3,
                weekly_days_off = $4, created_by_uid = $5, created_at = now()
          WHERE id = $1`,
        [same.id, values.dailyWorkHours, values.shiftHours, values.weeklyDaysOff ?? [], actorUid],
      );
    } else {
      await tx.query(
        `UPDATE employee_compensation_history SET monthly_salary = $2,
                created_by_uid = $3, created_at = now() WHERE id = $1`,
        [same.id, values.monthlySalary, actorUid],
      );
    }
    return;
  }

  const predecessor = rows.filter((row) => dateOnly(row.effectiveFrom) < effectiveFrom).at(-1);
  const successor = rows.find((row) => dateOnly(row.effectiveFrom) > effectiveFrom);
  if (predecessor) {
    const end = predecessor.effectiveTo ? dateOnly(predecessor.effectiveTo) : null;
    if (end === null || end > effectiveFrom) {
      await tx.query(`UPDATE ${table} SET effective_to = $2 WHERE id = $1`, [predecessor.id, effectiveFrom]);
    }
  }
  const effectiveTo = successor ? dateOnly(successor.effectiveFrom) : null;
  if (kind === "schedule") {
    await tx.query(
      `INSERT INTO employee_schedule_history
        (member_id, effective_from, effective_to, daily_work_hours, shift_hours,
         weekly_days_off, created_by_uid)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [memberId, effectiveFrom, effectiveTo, values.dailyWorkHours, values.shiftHours, values.weeklyDaysOff ?? [], actorUid],
    );
  } else {
    await tx.query(
      `INSERT INTO employee_compensation_history
        (member_id, effective_from, effective_to, monthly_salary, created_by_uid)
       VALUES ($1, $2, $3, $4, $5)`,
      [memberId, effectiveFrom, effectiveTo, values.monthlySalary, actorUid],
    );
  }
}

function requireTodayOrFuture(value: string): void {
  const today = businessDate(new Date());
  if (value < today) throw precondition("Effective date must be today or in the future.");
}

function businessDate(value: Date): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Kolkata",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(value);
}

function parseShiftDurationHours(value: string): number {
  return parseShiftHours(value).durationMinutes / 60;
}

function dateOnly(value: string | Date): string {
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return parseDate(value, "effectiveDate");
}

function scheduleDto(row: HistoryRow): Row {
  return {
    id: row.id,
    effectiveFrom: dateOnly(row.effectiveFrom),
    effectiveTo: row.effectiveTo ? dateOnly(row.effectiveTo) : null,
    dailyWorkHours: Number(row.dailyWorkHours),
    shiftHours: row.shiftHours,
    weeklyDaysOff: weeklyDaysOffFrom(row.weeklyDaysOff),
  };
}

function compensationDto(row: HistoryRow): Row {
  return {
    id: row.id,
    effectiveFrom: dateOnly(row.effectiveFrom),
    effectiveTo: row.effectiveTo ? dateOnly(row.effectiveTo) : null,
    monthlySalary: Number(row.monthlySalary),
  };
}
