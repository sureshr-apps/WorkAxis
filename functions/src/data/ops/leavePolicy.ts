import type { Actor } from "../../auth/roles";
import type { SqlExecutor } from "../../db/executor";
import { denied, invalid, notFound } from "../../errors";
import {
  loadEmploymentDates,
  loadLeaveHistory,
  loadLeavePolicy,
  ledgerInput,
} from "../../leave/leavePolicyStore";
import { previewLeave } from "../../leave/leavePreview";
import { workDateString } from "../../time/workDate";
import { reqNumber, reqString } from "../../util/input";
import { requireRole } from "../authz";
import type { OperationRegistry } from "../operation";
import { selectOne } from "../sql";
import { optId, reqId } from "../vars";

type Row = Record<string, unknown>;

const MEMBER_ROLES = ["orgAdmin", "branchManager", "employee"] as const;

function requireOrganization(actor: Actor): string {
  if (!actor.organizationId) throw denied("Organization context is required.");
  return actor.organizationId;
}

function reqBool(vars: Row, key: string): boolean {
  const value = vars[key];
  if (typeof value !== "boolean") throw invalid(`${key} must be true or false.`);
  return value;
}

function calendarDate(vars: Row, key: string): string {
  const value = reqString(vars, key, 10, 10);
  const parsed = new Date(`${value}T00:00:00.000Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || parsed.toISOString().slice(0, 10) !== value) {
    throw invalid(`${key} must be a valid calendar date.`);
  }
  return value;
}

interface LeaveTypeRow {
  id: string;
  name: string;
  paid: boolean;
  yearlyDays: number;
  carryForward: boolean;
}

/** Leave types of the organization with the allowance in force today. */
async function currentTypes(
  db: SqlExecutor,
  organizationId: string,
  today: string,
): Promise<LeaveTypeRow[]> {
  return db.query<LeaveTypeRow>(
    `SELECT t.id, t.name, t.paid,
            a.yearly_days AS "yearlyDays", a.carry_forward AS "carryForward"
       FROM leave_type t
       LEFT JOIN LATERAL (
         SELECT yearly_days, carry_forward FROM leave_type_allowance
          WHERE leave_type_id = t.id AND effective_from <= $2::date
          ORDER BY effective_from DESC LIMIT 1
       ) a ON true
      WHERE t.organization_id = $1 AND t.archived_at IS NULL
      ORDER BY t.sort_order, lower(t.name), t.id`,
    [organizationId, today],
  ).then((rows) =>
    rows.map((row) => ({
      ...row,
      yearlyDays: row.paid ? Number(row.yearlyDays ?? 0) : 0,
      carryForward: row.paid ? row.carryForward === true : false,
    })),
  );
}

async function monthlyAccrualOn(db: SqlExecutor, organizationId: string, date: string): Promise<boolean> {
  const row = await selectOne<{ monthlyAccrual: boolean }>(
    db,
    `SELECT monthly_accrual AS "monthlyAccrual" FROM organization_leave_policy
      WHERE organization_id = $1 AND effective_from <= $2::date
      ORDER BY effective_from DESC LIMIT 1`,
    [organizationId, date],
  );
  return row?.monthlyAccrual === true;
}

/** Records an allowance version effective today (replacing one made earlier today). */
async function setAllowance(
  db: SqlExecutor,
  leaveTypeId: string,
  today: string,
  yearlyDays: number,
  carryForward: boolean,
  uid: string,
): Promise<void> {
  await db.query(
    `INSERT INTO leave_type_allowance
       (leave_type_id, effective_from, yearly_days, carry_forward, created_by_uid)
     VALUES ($1, $2::date, $3, $4, $5)
     ON CONFLICT (leave_type_id, effective_from)
     DO UPDATE SET yearly_days = EXCLUDED.yearly_days,
                   carry_forward = EXCLUDED.carry_forward,
                   created_by_uid = EXCLUDED.created_by_uid,
                   created_at = now()`,
    [leaveTypeId, today, yearlyDays, carryForward, uid],
  );
}

const NAME_IN_USE = "Another leave type already uses that name.";

export const leavePolicyOps: OperationRegistry = {
  // The organization's active leave types, for the leave request form.
  ListLeaveTypes: async ({ db, actor }) => {
    requireRole(actor, MEMBER_ROLES);
    const organizationId = requireOrganization(actor);
    const leaveTypes = (await currentTypes(db, organizationId, workDateString(new Date())))
      .map(({ id, name, paid }) => ({ id, name, paid }));
    return { leaveTypes };
  },

  // Org Admin: types with today's allowances and the monthly-accrual flag.
  GetLeavePolicy: async ({ db, actor }) => {
    requireRole(actor, ["orgAdmin"]);
    const organizationId = requireOrganization(actor);
    const today = workDateString(new Date());
    const [leaveTypes, monthlyAccrual] = await Promise.all([
      currentTypes(db, organizationId, today),
      monthlyAccrualOn(db, organizationId, today),
    ]);
    return { leavePolicy: { monthlyAccrual, leaveTypes } };
  },

  // Org Admin: create a type, or rename / change the allowance of one. An
  // allowance change applies from today; earlier days keep the old one.
  SaveLeaveType: async ({ db, actor }, vars) => {
    requireRole(actor, ["orgAdmin"]);
    const organizationId = requireOrganization(actor);
    const id = optId(vars, "id");
    const name = reqString(vars, "name", 1, 60).trim();
    if (!name) throw invalid("Enter a leave type name.");
    const yearlyDays = reqNumber(vars, "yearlyDays", 0, 366);
    if (Math.round(yearlyDays * 100) !== yearlyDays * 100) {
      throw invalid("yearlyDays allows at most two decimal places.");
    }
    const carryForward = reqBool(vars, "carryForward");
    const today = workDateString(new Date());
    return db.transaction(async (tx) => {
      const duplicate = await selectOne<{ id: string }>(
        tx,
        `SELECT id FROM leave_type
          WHERE organization_id = $1 AND archived_at IS NULL
            AND lower(btrim(name)) = lower($2) AND ($3::text IS NULL OR id <> $3)
          LIMIT 1`,
        [organizationId, name, id ?? null],
      );
      if (duplicate) throw invalid(NAME_IN_USE);
      let typeId = id;
      if (id) {
        const existing = await selectOne<{ paid: boolean }>(
          tx,
          `SELECT paid FROM leave_type
            WHERE id = $1 AND organization_id = $2 AND archived_at IS NULL FOR UPDATE`,
          [id, organizationId],
        );
        if (!existing) throw notFound("Leave type not found.");
        if (!existing.paid && (yearlyDays > 0 || carryForward)) {
          throw invalid("Unpaid leave has no allowance.");
        }
        await tx.query(`UPDATE leave_type SET name = $2 WHERE id = $1`, [id, name]);
        if (existing.paid) {
          const current = await selectOne<{ yearlyDays: number; carryForward: boolean }>(
            tx,
            `SELECT yearly_days AS "yearlyDays", carry_forward AS "carryForward"
               FROM leave_type_allowance
              WHERE leave_type_id = $1 AND effective_from <= $2::date
              ORDER BY effective_from DESC LIMIT 1`,
            [id, today],
          );
          if (
            !current ||
            Number(current.yearlyDays) !== yearlyDays ||
            current.carryForward !== carryForward
          ) {
            await setAllowance(tx, id, today, yearlyDays, carryForward, actor.uid);
          }
        }
      } else {
        const created = await tx.query<{ id: string }>(
          `INSERT INTO leave_type (organization_id, name, paid, sort_order)
           VALUES ($1, $2, true, 50) RETURNING id`,
          [organizationId, name],
        );
        typeId = created[0].id;
        await setAllowance(tx, typeId, today, yearlyDays, carryForward, actor.uid);
      }
      const leaveType = (await currentTypes(tx, organizationId, today)).find((t) => t.id === typeId);
      return { leaveType };
    });
  },

  // Org Admin: hide a type from new requests. Existing requests keep it.
  ArchiveLeaveType: async ({ db, actor }, vars) => {
    requireRole(actor, ["orgAdmin"]);
    const organizationId = requireOrganization(actor);
    const id = reqId(vars, "id");
    const rows = await db.query<{ id: string }>(
      `UPDATE leave_type SET archived_at = now()
        WHERE id = $1 AND organization_id = $2 AND archived_at IS NULL AND paid
        RETURNING id`,
      [id, organizationId],
    );
    if (!rows[0]) throw notFound("Leave type not found, or it cannot be removed.");
    return { leaveType: { id } };
  },

  // Org Admin: monthly accrual on or off, from today.
  SetLeaveAccrual: async ({ db, actor }, vars) => {
    requireRole(actor, ["orgAdmin"]);
    const organizationId = requireOrganization(actor);
    const monthlyAccrual = reqBool(vars, "monthlyAccrual");
    const today = workDateString(new Date());
    await db.query(
      `INSERT INTO organization_leave_policy
         (organization_id, effective_from, monthly_accrual, created_by_uid)
       VALUES ($1, $2::date, $3, $4)
       ON CONFLICT (organization_id, effective_from)
       DO UPDATE SET monthly_accrual = EXCLUDED.monthly_accrual,
                     created_by_uid = EXCLUDED.created_by_uid,
                     created_at = now()`,
      [organizationId, today, monthlyAccrual, actor.uid],
    );
    return { leavePolicy: { monthlyAccrual } };
  },

  // How many days of a leave would be paid if approved now. Applicants
  // preview their own draft (leaveTypeId, startDate, endDate, optional id of
  // the pending request being edited); reviewers pass the request `id`.
  PreviewLeaveRequest: async ({ db, actor }, vars) => {
    requireRole(actor, MEMBER_ROLES);
    const organizationId = requireOrganization(actor);
    const reviewing = vars.leaveTypeId === undefined || vars.leaveTypeId === null;
    let request: { id: string; leaveTypeId: string; startDate: string; endDate: string };
    let member: { id: string; authUid: string } | null;
    if (reviewing) {
      requireRole(actor, ["orgAdmin", "branchManager"]);
      const row = await selectOne<{
        id: string; leaveTypeId: string; startDate: string; endDate: string;
        memberId: string; authUid: string; branchId: string; applicantRole: string;
        organizationId: string;
      }>(
        db,
        `SELECT id, leave_type_id AS "leaveTypeId",
                to_char(start_date, 'YYYY-MM-DD') AS "startDate",
                to_char(end_date, 'YYYY-MM-DD') AS "endDate",
                applicant_member_id AS "memberId", applicant_uid AS "authUid",
                branch_id AS "branchId", applicant_role AS "applicantRole",
                organization_id AS "organizationId"
           FROM leave_request WHERE id = $1`,
        [reqId(vars, "id")],
      );
      const inScope =
        row !== null &&
        row.organizationId === organizationId &&
        (actor.role === "orgAdmin" ||
          (row.applicantRole === "employee" &&
            actor.branchIds.includes(row.branchId) &&
            reqId(vars, "activeBranchId") === row.branchId));
      if (!row || !inScope) throw notFound("Leave request not found.");
      request = row;
      member = { id: row.memberId, authUid: row.authUid };
    } else {
      requireRole(actor, ["branchManager", "employee"]);
      const leaveTypeId = reqId(vars, "leaveTypeId");
      const startDate = calendarDate(vars, "startDate");
      const endDate = calendarDate(vars, "endDate");
      if (endDate < startDate) throw invalid("End date must be on or after start date.");
      const type = await selectOne<{ id: string }>(
        db,
        `SELECT id FROM leave_type WHERE id = $1 AND organization_id = $2`,
        [leaveTypeId, organizationId],
      );
      if (!type) throw notFound("Leave type not found.");
      member = await selectOne<{ id: string; authUid: string }>(
        db,
        `SELECT id, auth_uid AS "authUid" FROM organization_member
          WHERE auth_uid = $1 AND organization_id = $2 LIMIT 1`,
        [actor.uid, organizationId],
      );
      if (!member) throw denied("Member not found.");
      request = { id: optId(vars, "id") ?? "preview", leaveTypeId, startDate, endDate };
    }
    const [policy, history, employment] = await Promise.all([
      loadLeavePolicy(db, organizationId),
      loadLeaveHistory(db, organizationId, [member.id], request.endDate),
      loadEmploymentDates([member.authUid]),
    ]);
    const preview = previewLeave(
      ledgerInput(policy, history.get(member.id), employment.get(member.authUid)),
      request,
    );
    return { leavePreview: { leaveTypeId: request.leaveTypeId, ...preview } };
  },
};
