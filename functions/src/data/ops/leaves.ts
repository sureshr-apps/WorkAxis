import { denied, invalid } from "../../errors";
import type { Actor } from "../../auth/roles";
import type { SqlExecutor } from "../../db/executor";
import { requireRole } from "../authz";
import type { OperationContext, OperationRegistry } from "../operation";
import { reqEnum, reqString } from "../../util/input";
import { insertReturningId, paged, Query, raw, selectOne } from "../sql";
import { optId, optText, pageVars, reqId } from "../vars";

type Row = Record<string, unknown>;

const LEAVE_TYPES = ["annual", "sick", "personal", "unpaid"] as const;
const REVIEW_STATUSES = ["approved", "rejected"] as const;
const SUBMITTERS = ["employee", "branchManager"] as const;
const LEAVE_COLUMNS = `r.id, r.organization_id AS "organizationId",
  r.branch_id AS "branchId", b.name AS "branchName",
  r.applicant_member_id AS "applicantMemberId", r.applicant_uid AS "applicantUid",
  r.applicant_name AS "applicantName", r.applicant_role AS "applicantRole",
  r.leave_type AS "leaveType", to_char(r.start_date, 'YYYY-MM-DD') AS "startDate",
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
  leaveType: string;
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

function leaveType(vars: Row): (typeof LEAVE_TYPES)[number] {
  return reqEnum(vars, "leaveType", LEAVE_TYPES);
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

async function requireActiveBranch(
  db: SqlExecutor,
  actor: Actor,
  branchId: string,
): Promise<void> {
  const branch = await selectOne<{ organizationId: string; status: string }>(
    db,
    `SELECT organization_id AS "organizationId", status FROM branch WHERE id = $1`,
    [branchId],
  );
  if (
    !branch ||
    branch.status !== "active" ||
    branch.organizationId !== actor.organizationId ||
    !actor.branchIds.includes(branchId)
  ) {
    throw denied("Branch not found or access denied.");
  }
}

async function loadRequest(db: SqlExecutor, id: string): Promise<LeaveRow | null> {
  return selectOne<LeaveRow>(
    db,
    `SELECT ${LEAVE_COLUMNS}
       FROM leave_request r JOIN branch b ON b.id = r.branch_id
      WHERE r.id = $1`,
    [id],
  );
}

function requireCustomerActor(actor: Actor): string {
  if (!actor.organizationId) throw denied("Organization context is required.");
  return actor.organizationId;
}

export const leavesOps: OperationRegistry = {
  ListMyLeaveRequests: async ({ db, actor }, vars) => {
    requireRole(actor, SUBMITTERS);
    const { limit, offset } = pageVars(vars);
    const q = new Query()
      .eq("r.applicant_uid", actor.uid)
      .eq("r.status", parseStatus(vars));
    const { rows, total } = await paged<LeaveRow>(db, {
      columns: LEAVE_COLUMNS,
      from: "leave_request r JOIN branch b ON b.id = r.branch_id",
      q,
      orderBy: "r.created_at DESC, r.id DESC",
      limit,
      offset,
    });
    return { leaveRequests: rows, total };
  },

  ListOrganizationLeaveRequestsPaged: async ({ db, actor }, vars) => {
    requireRole(actor, ["orgAdmin"]);
    const orgId = requireCustomerActor(actor);
    const { limit, offset } = pageVars(vars);
    const q = new Query()
      .eq("r.organization_id", orgId)
      .eq("r.branch_id", optId(vars, "branchId"))
      .eq("r.status", parseStatus(vars));
    const { rows, total } = await paged<LeaveRow>(db, {
      columns: LEAVE_COLUMNS,
      from: "leave_request r JOIN branch b ON b.id = r.branch_id",
      q,
      orderBy: "r.created_at DESC, r.id DESC",
      limit,
      offset,
    });
    return { leaveRequests: rows, total };
  },

  ListEmployeeLeaveRequestsByBranchPaged: async ({ db, actor }, vars) => {
    requireRole(actor, ["branchManager"]);
    const branchId = reqId(vars, "branchId");
    await requireActiveBranch(db, actor, branchId);
    const { limit, offset } = pageVars(vars);
    const q = new Query()
      .eq("r.branch_id", branchId)
      .eq("r.applicant_role", "employee")
      .eq("r.status", parseStatus(vars));
    const { rows, total } = await paged<LeaveRow>(db, {
      columns: LEAVE_COLUMNS,
      from: "leave_request r JOIN branch b ON b.id = r.branch_id",
      q,
      orderBy: "r.created_at DESC, r.id DESC",
      limit,
      offset,
    });
    return { leaveRequests: rows, total };
  },

  SubmitLeaveRequest: async ({ db, actor }, vars) => {
    requireRole(actor, SUBMITTERS);
    const branchId = reqId(vars, "branchId");
    if (actor.role === "branchManager") {
      const activeBranchId = reqId(vars, "activeBranchId");
      if (activeBranchId !== branchId) throw denied("Use the active branch context.");
    }
    const { startDate, endDate } = leaveDates(vars);
    const type = leaveType(vars);
    const reason = reasonText(vars);
    const organizationId = requireCustomerActor(actor);
    return db.transaction(async (tx) => {
      await requireActiveBranch(tx, actor, branchId);
      const applicant = await findMe(tx, actor.uid);
      if (!applicant) throw denied("Applicant not found.");
      const { id } = await insertReturningId(tx, "leave_request", [
        ["organization_id", organizationId],
        ["branch_id", branchId],
        ["applicant_member_id", applicant.id],
        ["applicant_uid", actor.uid],
        ["applicant_name", applicant.fullName],
        ["applicant_role", actor.role],
        ["leave_type", type],
        ["start_date", startDate],
        ["end_date", endDate],
        ["reason", reason],
        ["status", "pending"],
        ["created_at", raw("now()")],
        ["updated_at", raw("now()")],
      ]);
      const leaveRequest = await loadRequest(tx, id);
      if (!leaveRequest) throw denied("Leave request could not be loaded.");
      return { leaveRequest };
    });
  },

  UpdateMyPendingLeaveRequest: async ({ db, actor }, vars) => {
    requireRole(actor, SUBMITTERS);
    const id = reqId(vars, "id");
    const organizationId = requireCustomerActor(actor);
    const activeBranchId = actor.role === "branchManager"
      ? reqId(vars, "activeBranchId")
      : undefined;
    const { startDate, endDate } = leaveDates(vars);
    const type = leaveType(vars);
    const reason = reasonText(vars);
    return db.transaction(async (tx) => {
      if (activeBranchId) await requireActiveBranch(tx, actor, activeBranchId);
      const rows = await tx.query<{ id: string }>(
        `UPDATE leave_request
            SET leave_type = $3, start_date = $4, end_date = $5,
                reason = $6, updated_at = now()
          WHERE id = $1 AND applicant_uid = $2 AND status = 'pending'
            AND organization_id = $7 AND applicant_role = $8
            AND ($9::text IS NULL OR branch_id = $9)
          RETURNING id`,
        [
          id,
          actor.uid,
          type,
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
        await requireActiveBranch(tx, actor, existing.branchId);
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
