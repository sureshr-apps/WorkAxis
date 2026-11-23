import { denied, invalid } from "../../errors";
import type { Actor } from "../../auth/roles";
import type { SqlExecutor } from "../../db/executor";
import { requireActiveBranch, requireBranchManagerContext, requireRole } from "../authz";
import { creationKey, idempotentCreate } from "../idempotency";
import type { OperationContext, OperationRegistry } from "../operation";
import { reqEnum, reqString } from "../../util/input";
import { insertReturningId, paged, Query, raw, selectOne } from "../sql";
import { optId, optText, pageVars, reqId } from "../vars";

type Row = Record<string, unknown>;

const REVIEW_STATUSES = ["approved", "rejected"] as const;
const SUBMITTERS = ["employee", "branchManager"] as const;
const LEAVE_COLUMNS = `r.id, r.organization_id AS "organizationId",
  r.branch_id AS "branchId", b.name AS "branchName",
  r.applicant_member_id AS "applicantMemberId", r.applicant_uid AS "applicantUid",
  r.applicant_name AS "applicantName", r.applicant_role AS "applicantRole",
  r.leave_type_id AS "leaveTypeId",
  lt.name AS "leaveTypeName", lt.paid AS "leaveTypePaid",
  to_char(r.start_date, 'YYYY-MM-DD') AS "startDate",
  to_char(r.end_date, 'YYYY-MM-DD') AS "endDate", r.reason, r.status,
  r.reviewer_uid AS "reviewerUid", r.reviewer_name AS "reviewerName",
  r.reviewer_notes AS "reviewerNotes", r.reviewed_at AS "reviewedAt",
  r.created_at AS "createdAt", r.updated_at AS "updatedAt"`;

interface LeaveRow extends Row {
  id: string;
  organizationId: string;
  branchId: string;
  branchName: string;
  applicantMemberId: string;
  applicantUid: string;
  applicantName: string;
  applicantRole: "employee" | "branchManager";
  leaveTypeId: string;
  leaveTypeName: string;
  leaveTypePaid: boolean;
  startDate: string;
  endDate: string;
  reason: string;
  status: string;
}

interface MemberRef {
  id: string;
  fullName: string;
}

async function findMe(db: SqlExecutor, uid: string): Promise<MemberRef | null> {
  return selectOne<MemberRef>(
    db,
    `SELECT id, full_name AS "fullName"
       FROM organization_member WHERE auth_uid = $1 LIMIT 1`,
    [uid],
  );
}

/** Tables every leave query reads from. */
const LEAVE_FROM = `leave_request r JOIN branch b ON b.id = r.branch_id
  JOIN leave_type lt ON lt.id = r.leave_type_id`;

/** The active leave type of the organization a request uses. */
async function requireLeaveType(
  db: SqlExecutor,
  organizationId: string,
  leaveTypeId: string,
): Promise<void> {
  const type = await selectOne<{ id: string }>(
    db,
    `SELECT id FROM leave_type
      WHERE id = $1 AND organization_id = $2 AND archived_at IS NULL`,
    [leaveTypeId, organizationId],
  );
  if (!type) throw invalid("Choose an available leave type.");
}

function dateOnly(vars: Row, key: string): string {
  const value = reqString(vars, key, 10, 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw invalid(`${key} must be a calendar date.`);
  }
  const parsed = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== value) {
    throw invalid(`${key} must be a valid calendar date.`);
  }
  return value;
}

function leaveDates(vars: Row): { startDate: string; endDate: string } {
  const startDate = dateOnly(vars, "startDate");
  const endDate = dateOnly(vars, "endDate");
  if (endDate < startDate) throw invalid("End date must be on or after start date.");
  return { startDate, endDate };
}

function reasonText(vars: Row): string {
  const value = reqString(vars, "reason", 1, 2000).trim();
  if (!value) throw invalid("A reason is required.");
  return value;
}

function parseStatus(vars: Row): string | undefined {
  const value = vars.status;
  if (value === undefined || value === null || value === "") return undefined;
  if (value !== "pending" && value !== "approved" && value !== "rejected") {
    throw invalid("Invalid leave request status.");
  }
  return value;
}

/** An active branch of the actor's organization that the actor is assigned to. */
async function requireAssignedActiveBranch(
  db: SqlExecutor,
  actor: Actor,
  branchId: string,
): Promise<void> {
  if (!actor.branchIds.includes(branchId)) throw denied("Branch not found or access denied.");
  await requireActiveBranch(db, branchId, actor.organizationId);
}

/** The leave request a previous attempt of this request created. */
async function priorLeaveRequest(db: SqlExecutor, key: string) {
  const prior = await selectOne<{ id: string; fingerprint: string | null }>(
    db,
    `SELECT id, creation_fingerprint AS fingerprint
       FROM leave_request WHERE creation_request_key = $1`,
    [key],
  );
  if (!prior) return null;
  const leaveRequest = await loadRequest(db, prior.id);
  if (!leaveRequest) return null;
  return { fingerprint: prior.fingerprint, result: { leaveRequest } };
}

async function loadRequest(db: SqlExecutor, id: string): Promise<LeaveRow | null> {
  return selectOne<LeaveRow>(
    db,
    `SELECT ${LEAVE_COLUMNS}
       FROM ${LEAVE_FROM}
      WHERE r.id = $1`,
    [id],
  );
}

function requireCustomerActor(actor: Actor): string {
  if (!actor.organizationId) throw denied("Organization context is required.");
  return actor.organizationId;
}

/** List scopes shared by the paged list and count operations. */
const LEAVE_SCOPES = ["mine", "branchEmployees", "organization"] as const;
type LeaveScopeName = (typeof LEAVE_SCOPES)[number];

/**
 * Authorization and base filters for one leave scope: `mine` (the caller's
 * own requests), `branchEmployees` (employee requests of a branch the Branch
 * Manager is assigned to), or `organization` (Org Admin, optional branchId).
 */
async function leaveScope(
  db: SqlExecutor,
  actor: Actor,
  vars: Row,
  scope: LeaveScopeName,
): Promise<Query> {
  if (scope === "mine") {
    requireRole(actor, SUBMITTERS);
    return new Query().eq("r.applicant_uid", actor.uid);
  }
  if (scope === "branchEmployees") {
    requireRole(actor, ["branchManager"]);
    const branchId = reqId(vars, "branchId");
    await requireAssignedActiveBranch(db, actor, branchId);
    return new Query().eq("r.branch_id", branchId).eq("r.applicant_role", "employee");
  }
  requireRole(actor, ["orgAdmin"]);
  const orgId = requireCustomerActor(actor);
  return new Query().eq("r.organization_id", orgId).eq("r.branch_id", optId(vars, "branchId"));
}

/** Pending requests first, then by start date (the order the screen shows). */
const LEAVE_ORDER = "(r.status = 'pending') DESC, r.start_date ASC, r.created_at DESC, r.id DESC";

async function listLeaveRequests(
  { db, actor }: OperationContext,
  vars: Row,
  scopeName: LeaveScopeName,
): Promise<unknown> {
  const q = await leaveScope(db, actor, vars, scopeName);
  const { limit, offset } = pageVars(vars);
  q.eq("r.status", parseStatus(vars));
  const { rows, total } = await paged<LeaveRow>(db, {
    columns: LEAVE_COLUMNS,
    from: LEAVE_FROM,
    q,
    orderBy: LEAVE_ORDER,
    limit,
    offset,
  });
  return { leaveRequests: rows, total };
}

export const leavesOps: OperationRegistry = {
  ListMyLeaveRequests: (ctx, vars) => listLeaveRequests(ctx, vars, "mine"),
  ListOrganizationLeaveRequestsPaged: (ctx, vars) =>
    listLeaveRequests(ctx, vars, "organization"),
  ListEmployeeLeaveRequestsByBranchPaged: (ctx, vars) =>
    listLeaveRequests(ctx, vars, "branchEmployees"),

  // Status counts for one list scope (KPI tiles and filter chips).
  GetLeaveStatusCounts: async ({ db, actor }, vars) => {
    const scope = await leaveScope(db, actor, vars, reqEnum(vars, "scope", LEAVE_SCOPES));
    const rows = await db.query<{ status: string; count: number }>(
      `SELECT r.status, count(*)::int AS count
         FROM leave_request r ${scope.where} GROUP BY r.status`,
      scope.params,
    );
    const counts = { pending: 0, approved: 0, rejected: 0 };
    for (const row of rows) {
      if (row.status in counts) counts[row.status as keyof typeof counts] += Number(row.count);
    }
    return { counts };
  },

  SubmitLeaveRequest: async ({ db, actor }, vars) => {
    requireRole(actor, SUBMITTERS);
    const branchId = reqId(vars, "branchId");
    requireBranchManagerContext(actor, vars, branchId, "Use the active branch context.");
    const { startDate, endDate } = leaveDates(vars);
    const leaveTypeId = reqId(vars, "leaveTypeId");
    const reason = reasonText(vars);
    const organizationId = requireCustomerActor(actor);
    const creation = creationKey(actor, vars, {
      branchId, startDate, endDate, leaveTypeId, reason,
    });
    return idempotentCreate(db, creation, priorLeaveRequest, () => db.transaction(async (tx) => {
      await requireAssignedActiveBranch(tx, actor, branchId);
      const applicant = await findMe(tx, actor.uid);
      if (!applicant) throw denied("Applicant not found.");
      await requireLeaveType(tx, organizationId, leaveTypeId);
      const { id } = await insertReturningId(tx, "leave_request", [
        ["organization_id", organizationId],
        ["branch_id", branchId],
        ["applicant_member_id", applicant.id],
        ["applicant_uid", actor.uid],
        ["applicant_name", applicant.fullName],
        ["applicant_role", actor.role],
        ["leave_type_id", leaveTypeId],
        ["start_date", startDate],
        ["end_date", endDate],
        ["reason", reason],
        ["status", "pending"],
        ["creation_request_key", creation?.key],
        ["creation_fingerprint", creation?.fingerprint],
        ["created_at", raw("now()")],
        ["updated_at", raw("now()")],
      ]);
      const leaveRequest = await loadRequest(tx, id);
      if (!leaveRequest) throw denied("Leave request could not be loaded.");
      return { leaveRequest };
    }));
  },

  UpdateMyPendingLeaveRequest: async ({ db, actor }, vars) => {
    requireRole(actor, SUBMITTERS);
    const id = reqId(vars, "id");
    const organizationId = requireCustomerActor(actor);
    const activeBranchId = actor.role === "branchManager"
      ? reqId(vars, "activeBranchId")
      : undefined;
    const { startDate, endDate } = leaveDates(vars);
    const leaveTypeId = reqId(vars, "leaveTypeId");
    const reason = reasonText(vars);
    return db.transaction(async (tx) => {
      if (activeBranchId) await requireAssignedActiveBranch(tx, actor, activeBranchId);
      await requireLeaveType(tx, organizationId, leaveTypeId);
      const rows = await tx.query<{ id: string }>(
        `UPDATE leave_request
            SET leave_type_id = $3, start_date = $4, end_date = $5,
                reason = $6, updated_at = now()
          WHERE id = $1 AND applicant_uid = $2 AND status = 'pending'
            AND organization_id = $7 AND applicant_role = $8
            AND ($9::text IS NULL OR branch_id = $9)
          RETURNING id`,
        [
          id,
          actor.uid,
          leaveTypeId,
          startDate,
          endDate,
          reason,
          organizationId,
          actor.role,
          activeBranchId ?? null,
        ],
      );
      if (!rows[0]) throw denied("Pending leave request not found or access denied.");
      const leaveRequest = await loadRequest(tx, id);
      if (!leaveRequest) throw denied("Leave request could not be loaded.");
      return { leaveRequest };
    });
  },

  ReviewLeaveRequest: async ({ db, actor }: OperationContext, vars) => {
    requireRole(actor, ["orgAdmin", "branchManager"]);
    const id = reqId(vars, "id");
    const status = reqEnum(vars, "status", REVIEW_STATUSES);
    const notes = optText(vars, "reviewerNotes", 2000);
    return db.transaction(async (tx) => {
      const existing = await selectOne<{
        status: string;
        organizationId: string;
        branchId: string;
        applicantRole: string;
      }>(
        tx,
        `SELECT status, organization_id AS "organizationId",
                branch_id AS "branchId", applicant_role AS "applicantRole"
           FROM leave_request WHERE id = $1`,
        [id],
      );
      const inScope =
        existing !== null &&
        (actor.role === "orgAdmin"
          ? existing.organizationId === requireCustomerActor(actor)
          : existing.applicantRole === "employee" &&
            actor.branchIds.includes(existing.branchId) &&
            reqId(vars, "activeBranchId") === existing.branchId);
      if (!existing || existing.status !== "pending" || !inScope) {
        throw denied("Leave request not found, already reviewed, or access denied.");
      }
      if (actor.role === "branchManager") {
        await requireAssignedActiveBranch(tx, actor, existing.branchId);
      }
      const reviewer = await findMe(tx, actor.uid);
      if (!reviewer) throw denied("Reviewer not found.");
      const rows = await tx.query<{ id: string }>(
        `UPDATE leave_request
            SET status = $2, reviewer_uid = $3, reviewer_name = $4,
                reviewer_notes = $5, reviewed_at = now(), updated_at = now()
          WHERE id = $1 AND status = 'pending'
          RETURNING id`,
        [id, status, actor.uid, reviewer.fullName, notes ?? null],
      );
      if (!rows[0]) throw denied("Leave request was already reviewed.");
      const leaveRequest = await loadRequest(tx, id);
      if (!leaveRequest) throw denied("Leave request could not be loaded.");
      return { leaveRequest };
    });
  },
};
