import type { Actor } from "../../auth/roles";
import type { SqlExecutor } from "../../db/executor";
import { denied, notFound } from "../../errors";
import { optString, reqEnum, reqNumber, reqString } from "../../util/input";
import { requireManagedBranch, requireOrgAdminScope, requireRole } from "../authz";
import type { OperationContext, OperationRegistry } from "../operation";
import { nestBranchRef, RETURN_MANAGER_FIELDS, returnCols } from "../projections";
import { insertReturningId, paged, Query, raw, select, selectOne } from "../sql";
import { optText, pageVars, reqId } from "../vars";

type Row = Record<string, unknown>;

const MANAGER_COLS = returnCols("r", RETURN_MANAGER_FIELDS);
const BRANCH_REF = `b.id AS "branchRefId", b.name AS "branchRefName"`;
const MY_RETURN_COLS = returnCols("r", [
  "id",
  "employeeId",
  "employeeName",
  "invoiceNumber",
  "status",
  "returnReason",
  "productTitle",
  "quantity",
  "unit",
  "billImageUrl",
  "remarks",
  "reviewerNotes",
  "reviewerName",
  "reviewedAt",
  "createdAt",
]);

const SUBMITTER_ROLES = ["employee", "branchManager"] as const;
const REVIEWER_ROLES = ["orgAdmin", "branchManager"] as const;

interface MemberRef {
  id: string;
  authUid: string | null;
  fullName: string;
}

async function findMe(db: SqlExecutor, uid: string): Promise<MemberRef | null> {
  return selectOne<MemberRef>(
    db,
    `SELECT id, auth_uid AS "authUid", full_name AS "fullName"
       FROM organization_member WHERE auth_uid = $1 LIMIT 1`,
    [uid],
  );
}

interface NewReturn {
  id?: string;
  organizationId: string;
  branchId: string;
  employeeId: string;
  employeeName: string;
  customerName: string;
  amount: number;
  invoiceNumber: string;
  returnReason: string;
  productTitle?: string;
  quantity?: number;
  unit?: string;
  billImageUrl?: string;
  remarks?: string;
}

async function insertReturn(db: SqlExecutor, actor: Actor, r: NewReturn) {
  return insertReturningId(db, "return_record", [
    ["id", r.id ?? raw("gen_random_uuid()::text")],
    ["organization_id", r.organizationId],
    ["branch_id", r.branchId],
    ["employee_id", r.employeeId],
    ["employee_uid", actor.uid],
    ["employee_name", r.employeeName],
    ["customer_name", r.customerName],
    ["amount", r.amount],
    ["product_title", r.productTitle],
    ["quantity", r.quantity],
    ["unit", r.unit],
    ["invoice_number", r.invoiceNumber],
    ["status", "pending"],
    ["return_reason", r.returnReason],
    ["bill_image_url", r.billImageUrl],
    ["remarks", r.remarks],
    ["created_at", raw("now()")],
  ]);
}

/** Active branch of the actor's organization, else the original check message. */
async function requireActiveBranchOf(db: SqlExecutor, branchId: string, orgId: string | undefined) {
  const branch = await selectOne<{ status: string; organizationId: string }>(
    db,
    `SELECT status, organization_id AS "organizationId" FROM branch WHERE id = $1`,
    [branchId],
  );
  if (!branch || branch.status !== "active" || branch.organizationId !== orgId) {
    throw denied("Branch not found or inactive.");
  }
}

async function review(
  { db, actor }: OperationContext,
  vars: Row,
  withNotes: boolean,
): Promise<unknown> {
  requireRole(actor, REVIEWER_ROLES);
  const status = reqEnum(vars, "status", ["approved", "rejected"] as const);
  const id = reqId(vars, "id");
  const notes = withNotes ? optText(vars, "reviewerNotes") : undefined;
  return db.transaction(async (tx) => {
    const reviewer = await findMe(tx, actor.uid);
    if (!reviewer) throw denied("Reviewer not found.");
    const existing = await selectOne<{
      status: string;
      organizationId: string;
      branchId: string;
      employeeId: string | null;
      submitterUid: string | null;
    }>(
      tx,
      `SELECT status,
              organization_id AS "organizationId",
              branch_id AS "branchId",
              employee_id AS "employeeId",
              employee_uid AS "submitterUid"
         FROM return_record WHERE id = $1`,
      [id],
    );
    const inScope =
      existing !== null &&
      ((actor.role === "orgAdmin" && existing.organizationId === actor.organizationId) ||
        (actor.role === "branchManager" && actor.branchIds.includes(existing.branchId)));
    const isOwnBranchManagerReturn =
      actor.role === "branchManager" &&
      existing !== null &&
      (existing.submitterUid === actor.uid ||
        existing.employeeId === actor.uid ||
        existing.employeeId === reviewer.id);
    if (!existing || existing.status !== "pending" || !inScope || isOwnBranchManagerReturn) {
      throw denied("Return not found, already reviewed, or access denied.");
    }
    const rows = await tx.query<{ id: string }>(
      `UPDATE return_record
          SET status = $2,
              reviewer_notes = COALESCE($3, reviewer_notes),
              reviewer_uid = $4,
              reviewer_name = $5,
              reviewed_at = now()
        WHERE id = $1 AND status = 'pending'
        RETURNING id`,
      [id, status, notes ?? null, actor.uid, reviewer.fullName],
    );
    if (!rows[0]) throw denied("Return not found, already reviewed, or access denied.");
    return { returnRecord_update: { id: rows[0].id } };
  });
}

async function updateReturnRecord(
  { db, actor }: OperationContext,
  vars: Row,
): Promise<unknown> {
  requireRole(actor, SUBMITTER_ROLES);
  const id = reqId(vars, "id");
  const productTitle = reqString(vars, "productTitle", 1, 200);
  const quantity = reqNumber(vars, "quantity", Number.MIN_VALUE, 1e9);
  const unit = reqString(vars, "unit", 1, 32);
  const invoiceNumber = reqString(vars, "invoiceNumber", 1, 100);
  const returnReason = reqString(vars, "returnReason", 1, 1000);
  const billImageUrl = optText(vars, "billImageUrl", 2048);
  const remarks = optText(vars, "remarks", 2000);
  const organizationId = actor.organizationId;
  if (!organizationId) throw denied();

  return db.transaction(async (tx) => {
    const member = await findMe(tx, actor.uid);
    if (!member) throw denied("Return submitter not found.");
    const existing = await selectOne<{
      status: string;
      organizationId: string;
      branchId: string;
      employeeId: string | null;
      submitterUid: string | null;
    }>(
      tx,
      `SELECT status,
              organization_id AS "organizationId",
              branch_id AS "branchId",
              employee_id AS "employeeId",
              employee_uid AS "submitterUid"
         FROM return_record WHERE id = $1 FOR UPDATE`,
      [id],
    );
    const isSubmitter = existing?.submitterUid != null
      ? existing.submitterUid === actor.uid
      : existing?.employeeId === actor.uid || existing?.employeeId === member.id;
    if (
      !existing ||
      existing.status !== "pending" ||
      existing.organizationId !== organizationId ||
      !isSubmitter ||
      !actor.branchIds.includes(existing.branchId)
    ) {
      throw denied("Return not found, already reviewed, or access denied.");
    }
    await requireActiveBranchOf(tx, existing.branchId, organizationId);

    const rows = await tx.query<{ id: string }>(
      `UPDATE return_record
          SET customer_name = $2,
              amount = $3,
              product_title = $2,
              quantity = $3,
              unit = $4,
              invoice_number = $5,
              return_reason = $6,
              bill_image_url = $7,
              remarks = $8
        WHERE id = $1 AND organization_id = $9 AND branch_id = $10
          AND status = 'pending'
        RETURNING id`,
      [
        id,
        productTitle,
        quantity,
        unit,
        invoiceNumber,
        returnReason,
        billImageUrl ?? null,
        remarks ?? null,
        organizationId,
        existing.branchId,
      ],
    );
    if (!rows[0]) throw denied("Return not found, already reviewed, or access denied.");
    return { returnRecord_update: { id: rows[0].id } };
  });
}

export const returnsOps: OperationRegistry = {
  // Org Admin: branches of own org. Branch Manager: only assigned branches.
  ListReturnsByBranch: async ({ db, actor }, vars) => {
    const branchId = reqId(vars, "branchId");
    await requireManagedBranch(db, actor, branchId);
    const returnRecords = await select(
      db,
      `SELECT ${MANAGER_COLS} FROM return_record r WHERE r.branch_id = $1
        ORDER BY r.created_at DESC LIMIT 200`,
      [branchId],
    );
    return { returnRecords };
  },

  ListReturnsByBranchPaged: async ({ db, actor }, vars) => {
    const branchId = reqId(vars, "branchId");
    const { limit, offset } = pageVars(vars);
    await requireManagedBranch(db, actor, branchId);
    const q = new Query()
      .eq("r.branch_id", branchId)
      .eq("r.status", optString(vars, "status", 1, 50));
    const { rows, total } = await paged(db, {
      columns: MANAGER_COLS,
      from: "return_record r",
      q,
      orderBy: "r.created_at DESC, r.id DESC",
      limit,
      offset,
    });
    return { returnRecords: rows, total };
  },

  ListReturnsByOrgPaged: async ({ db, actor }, vars) => {
    const orgId = reqId(vars, "orgId");
    requireOrgAdminScope(actor, orgId);
    const { limit, offset } = pageVars(vars);
    const q = new Query()
      .eq("r.organization_id", orgId)
      .eq("r.branch_id", optString(vars, "branchId", 1, 128))
      .eq("r.status", optString(vars, "status", 1, 50));
    const { rows, total } = await paged<Row>(db, {
      columns: `${MANAGER_COLS}, ${BRANCH_REF}`,
      from: "return_record r JOIN branch b ON b.id = r.branch_id",
      q,
      orderBy: "r.created_at DESC, r.id DESC",
      limit,
      offset,
    });
    return { returnRecords: rows.map(nestBranchRef), total };
  },

  // The caller's own returns (Employee, or a Branch Manager's own submissions).
  ListMyReturns: async ({ db, actor }, vars) => {
    const { limit, offset } = pageVars(vars);
    const q = new Query()
      .eq("r.employee_uid", actor.uid)
      .eq("r.status", optString(vars, "status", 1, 50));
    const { rows, total } = await paged<Row>(db, {
      columns: `${MY_RETURN_COLS}, ${BRANCH_REF}`,
      from: "return_record r JOIN branch b ON b.id = r.branch_id",
      q,
      orderBy: "r.created_at DESC, r.id DESC",
      limit,
      offset,
    });
    return { returnRecords: rows.map(nestBranchRef), total };
  },

  // Legacy signature (client-supplied id). The submitter must be an Employee
  // or Branch Manager of the branch; uid is stamped from the caller and the
  // supplied employeeId must be the caller's member id or uid.
  CreateReturnRecord: async ({ db, actor }, vars) => {
    requireRole(actor, SUBMITTER_ROLES);
    const orgId = reqId(vars, "orgId");
    const branchId = reqId(vars, "branchId");
    const employeeId = reqId(vars, "employeeId");
    reqString(vars, "employeeName", 1, 200);
    if (actor.organizationId !== orgId || !actor.branchIds.includes(branchId)) throw denied();
    const input: NewReturn = {
      id: reqId(vars, "id"),
      organizationId: orgId,
      branchId,
      employeeId,
      employeeName: "",
      customerName: reqString(vars, "customerName", 1, 200),
      invoiceNumber: reqString(vars, "invoiceNumber", 1, 100),
      returnReason: reqString(vars, "returnReason", 1, 1000),
      amount: reqNumber(vars, "amount", -1e9, 1e9),
      productTitle: optText(vars, "productTitle", 200),
      quantity: optQuantity(vars),
      unit: optText(vars, "unit", 32),
      billImageUrl: optText(vars, "billImageUrl", 2048),
      remarks: optText(vars, "remarks", 2000),
    };
    return db.transaction(async (tx) => {
      const me = await findMe(tx, actor.uid);
      if (!me || (me.id !== employeeId && me.authUid !== employeeId)) {
        throw denied("Submitter does not match the signed-in user.");
      }
      await requireActiveBranchOf(tx, branchId, orgId);
      const returnRecord_insert = await insertReturn(tx, actor, {
        ...input,
        employeeName: me.fullName,
      });
      return { returnRecord_insert };
    });
  },

  // Server-generated id; org, submitter id/name and uid are derived server-side.
  SubmitReturn: async ({ db, actor }, vars) => {
    requireRole(actor, SUBMITTER_ROLES);
    const branchId = reqId(vars, "branchId");
    const quantity = reqNumber(vars, "quantity", Number.MIN_VALUE, 1e9);
    const productTitle = reqString(vars, "productTitle", 1, 200);
    const input = {
      returnReason: reqString(vars, "returnReason", 1, 1000),
      unit: reqString(vars, "unit", 1, 32),
      invoiceNumber: reqString(vars, "invoiceNumber", 1, 100),
      billImageUrl: optText(vars, "billImageUrl", 2048),
      remarks: optText(vars, "remarks", 2000),
    };
    if (!actor.branchIds.includes(branchId)) throw denied();
    const orgId = actor.organizationId;
    if (!orgId) throw denied();
    return db.transaction(async (tx) => {
      const me = await findMe(tx, actor.uid);
      if (!me) throw notFound("Member not found.");
      await requireActiveBranchOf(tx, branchId, orgId);
      const returnRecord_insert = await insertReturn(tx, actor, {
        ...input,
        organizationId: orgId,
        branchId,
        employeeId: me.id,
        employeeName: me.fullName,
        customerName: productTitle,
        amount: quantity,
        productTitle,
        quantity,
      });
      return { returnRecord_insert };
    });
  },

  // The submitter may edit the row only while it remains pending.
  UpdateReturnRecord: (ctx, vars) => updateReturnRecord(ctx, vars),

  // Only an Org Admin of the org or another Branch Manager assigned to the
  // return's branch may review it. Only pending returns are reviewable.
  UpdateReturnRecordReview: (ctx, vars) => review(ctx, vars, true),

  // Legacy signature; same rules as UpdateReturnRecordReview, without notes.
  UpdateReturnRecordStatus: (ctx, vars) => review(ctx, vars, false),
};

function optQuantity(vars: Row): number | undefined {
  if (vars.quantity === undefined || vars.quantity === null) return undefined;
  return reqNumber(vars, "quantity", -1e9, 1e9);
}

