import type { Actor } from "../../auth/roles";
import type { SqlExecutor } from "../../db/executor";
import { denied, invalid, notFound } from "../../errors";
import { workDateString } from "../../time/workDate";
import { optString, reqEnum, reqNumber, reqString } from "../../util/input";
import {
  isOrgAdminOf,
  requireActiveBranch,
  requireManagedBranch,
  requireOrgAdminScope,
  requireRole,
} from "../authz";
import { type CreationKey, creationKey, idempotentCreate } from "../idempotency";
import type { OperationContext, OperationRegistry } from "../operation";
import { nestBranchRef, RETURN_MANAGER_FIELDS, returnCols } from "../projections";
import { insertReturningId, paged, Query, raw, select, selectOne } from "../sql";
import { optEnum, optText, pageVars, parseDate, reqId } from "../vars";

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
  "billNumber",
  "returnDate",
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
  billNumber?: string;
  /** Business date (`YYYY-MM-DD`, Asia/Kolkata); defaults to today. */
  returnDate?: string;
  creation?: CreationKey;
  creationLine?: number;
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
    ["bill_number", r.billNumber],
    ["return_date", r.returnDate ?? workDateString(new Date())],
    ["creation_request_key", r.creation?.key],
    ["creation_line", r.creation ? r.creationLine : undefined],
    ["creation_fingerprint", r.creation?.fingerprint],
    ["created_at", raw("now()")],
  ]);
}

/** Active branch of the actor's organization, else the original check message. */
const requireActiveBranchOf = (db: SqlExecutor, branchId: string, orgId: string | undefined) =>
  requireActiveBranch(db, branchId, orgId, () => denied("Branch not found or inactive."));

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

/** Most lines one bill may carry in a single SubmitReturnBatch call. */
const MAX_BATCH_LINES = 50;

/** Optional business return date; a return cannot be dated after today. */
function optReturnDate(vars: Row): string | undefined {
  const v = vars.returnDate;
  if (v === undefined || v === null || v === "") return undefined;
  const date = parseDate(v, "returnDate");
  if (date > workDateString(new Date())) {
    throw invalid("returnDate cannot be in the future.");
  }
  return date;
}

/** Bill-level fields shared by every line of one submission. */
function billHeader(vars: Row) {
  return {
    invoiceNumber: reqString(vars, "invoiceNumber", 1, 100),
    billNumber: optText(vars, "billNumber", 100),
    returnDate: optReturnDate(vars),
    billImageUrl: optText(vars, "billImageUrl", 2048),
  };
}

/** One returned product: title, quantity, unit, reason and remarks. */
function returnLine(vars: Row) {
  return {
    productTitle: reqString(vars, "productTitle", 1, 200),
    quantity: reqNumber(vars, "quantity", Number.MIN_VALUE, 1e9),
    unit: reqString(vars, "unit", 1, 32),
    returnReason: reqString(vars, "returnReason", 1, 1000),
    remarks: optText(vars, "remarks", 2000),
  };
}

function batchLines(vars: Row): Row[] {
  const items = vars.items;
  if (!Array.isArray(items) || items.length === 0 || items.length > MAX_BATCH_LINES) {
    throw invalid(`items must list between 1 and ${MAX_BATCH_LINES} returned products.`);
  }
  return items.map((item) => {
    if (typeof item !== "object" || item === null || Array.isArray(item)) {
      throw invalid("Each item must be an object.");
    }
    return item as Row;
  });
}

/** The lines a previous attempt of this request created, in line order. */
async function priorLines(db: SqlExecutor, key: string) {
  const rows = await select<{ id: string; fingerprint: string | null }>(
    db,
    `SELECT id, creation_fingerprint AS fingerprint
       FROM return_record WHERE creation_request_key = $1
      ORDER BY creation_line`,
    [key],
  );
  if (rows.length === 0) return null;
  return { fingerprint: rows[0].fingerprint, result: rows.map(({ id }) => ({ id })) };
}

/**
 * Inserts every line of one bill for the caller in a single transaction, so a
 * failure part-way leaves no partial bill behind. With a `requestId`, a retry
 * returns the lines the first attempt saved instead of saving them again.
 */
async function submitLines(
  { db, actor }: OperationContext,
  vars: Row,
  branchId: string,
  header: ReturnType<typeof billHeader>,
  lines: ReturnType<typeof returnLine>[],
): Promise<{ id: string }[]> {
  if (!actor.branchIds.includes(branchId)) throw denied();
  const orgId = actor.organizationId;
  if (!orgId) throw denied();
  const creation = creationKey(actor, vars, { branchId, header, lines });
  return idempotentCreate(db, creation, priorLines, () => db.transaction(async (tx) => {
    const me = await findMe(tx, actor.uid);
    if (!me) throw notFound("Member not found.");
    await requireActiveBranchOf(tx, branchId, orgId);
    const inserted: { id: string }[] = [];
    for (const [index, line] of lines.entries()) {
      inserted.push(
        await insertReturn(tx, actor, {
          ...header,
          ...line,
          organizationId: orgId,
          branchId,
          employeeId: me.id,
          employeeName: me.fullName,
          customerName: line.productTitle,
          amount: line.quantity,
          creation,
          creationLine: index,
        }),
      );
    }
    return inserted;
  }));
}

/** The list scopes shared by the paged list and count operations. */
const RETURN_SCOPES = ["mine", "branch", "organization"] as const;
type ReturnScopeName = (typeof RETURN_SCOPES)[number];

/** Rows submitted by the caller, including legacy rows without a uid. */
function submittedBy(q: Query, uid: string): string {
  const u = q.bind(uid);
  return `(r.employee_uid = ${u} OR (r.employee_uid IS NULL AND r.employee_id = ${u}))`;
}

/**
 * FROM clause, authorization and base filters for one returns scope:
 * `mine` (the caller's submissions), `branch` (a branch the caller manages;
 * optional `submitter` = mine | others), or `organization` (Org Admin, with
 * an optional `branchId`).
 */
async function returnScope(
  db: SqlExecutor,
  actor: Actor,
  vars: Row,
  scope: ReturnScopeName,
): Promise<{ from: string; q: Query; columns: string }> {
  const from = "return_record r JOIN branch b ON b.id = r.branch_id";
  const q = new Query();
  if (scope === "mine") {
    q.and(submittedBy(q, actor.uid));
    return { from, q, columns: `${MY_RETURN_COLS}, ${BRANCH_REF}` };
  }
  if (scope === "branch") {
    const branchId = reqId(vars, "branchId");
    await requireManagedBranch(db, actor, branchId);
    q.eq("r.branch_id", branchId);
    const submitter = optEnum(vars, "submitter", ["mine", "others"] as const);
    if (submitter === "mine") q.and(submittedBy(q, actor.uid));
    if (submitter === "others") q.and(`NOT ${submittedBy(q, actor.uid)}`);
    return { from, q, columns: `${MANAGER_COLS}, ${BRANCH_REF}` };
  }
  const orgId = reqId(vars, "orgId");
  requireOrgAdminScope(actor, orgId);
  q.eq("r.organization_id", orgId).eq("r.branch_id", optString(vars, "branchId", 1, 128));
  return { from, q, columns: `${MANAGER_COLS}, ${BRANCH_REF}` };
}

/** Newest business return date first (legacy rows use their creation day). */
const RETURN_ORDER =
  "COALESCE(r.return_date, (r.created_at AT TIME ZONE 'Asia/Kolkata')::date) DESC, " +
  "r.created_at DESC, r.id DESC";

/** One page of a scope, optionally narrowed by status and search text. */
async function listReturns(
  { db, actor }: OperationContext,
  vars: Row,
  scopeName: ReturnScopeName,
): Promise<unknown> {
  const { limit, offset } = pageVars(vars);
  const scope = await returnScope(db, actor, vars, scopeName);
  scope.q
    .eq("r.status", optString(vars, "status", 1, 50))
    .containsAny(
      [
        "r.product_title",
        "r.customer_name",
        "r.invoice_number",
        "r.bill_number",
        "r.employee_name",
        "b.name",
      ],
      optText(vars, "query", 100),
    );
  const { rows, total } = await paged<Row>(db, {
    columns: scope.columns,
    from: scope.from,
    q: scope.q,
    orderBy: RETURN_ORDER,
    limit,
    offset,
  });
  return { returnRecords: rows.map(nestBranchRef), total };
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

  ListReturnsByBranchPaged: (ctx, vars) => listReturns(ctx, vars, "branch"),
  ListReturnsByOrgPaged: (ctx, vars) => listReturns(ctx, vars, "organization"),
  // The caller's own returns (Employee, or a Branch Manager's own submissions).
  ListMyReturns: (ctx, vars) => listReturns(ctx, vars, "mine"),

  // Status counts for the same scopes as the list operations, ignoring the
  // status and text filters (they drive KPI tiles and filter chips).
  GetReturnStatusCounts: async ({ db, actor }, vars) => {
    const scope = await returnScope(db, actor, vars, reqEnum(vars, "scope", RETURN_SCOPES));
    const rows = await select<{ status: string; count: number }>(
      db,
      `SELECT r.status, count(*)::int AS count FROM ${scope.from} ${scope.q.where} GROUP BY r.status`,
      scope.q.params,
    );
    const counts = { pending: 0, approved: 0, rejected: 0 };
    for (const row of rows) {
      const status = String(row.status).toLowerCase();
      if (status in counts) counts[status as keyof typeof counts] += Number(row.count);
    }
    return { counts };
  },

  // One return the caller may see: their own, any in their Org Admin
  // organization, or any in a branch they manage. Null when out of scope.
  GetReturnById: async ({ db, actor }, vars) => {
    const id = reqId(vars, "id");
    const row = await selectOne<Row & { organizationId: string; branchRefId: string }>(
      db,
      `SELECT ${MANAGER_COLS}, r.organization_id AS "organizationId", ${BRANCH_REF}
         FROM return_record r JOIN branch b ON b.id = r.branch_id
        WHERE r.id = $1`,
      [id],
    );
    if (!row) return { returnRecord: null };
    const own =
      row.employeeUid === actor.uid || (row.employeeUid == null && row.employeeId === actor.uid);
    const manages =
      isOrgAdminOf(actor, row.organizationId) ||
      (actor.role === "branchManager" &&
        actor.organizationId === row.organizationId &&
        actor.branchIds.includes(row.branchRefId));
    if (!own && !manages) return { returnRecord: null };
    const { organizationId: _org, ...rest } = row;
    void _org;
    return { returnRecord: nestBranchRef(rest) };
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
  SubmitReturn: async (ctx, vars) => {
    requireRole(ctx.actor, SUBMITTER_ROLES);
    const branchId = reqId(vars, "branchId");
    const line = returnLine(vars);
    const header = billHeader(vars);
    const [returnRecord_insert] = await submitLines(ctx, vars, branchId, header, [line]);
    return { returnRecord_insert };
  },

  // Every line of one bill in one transaction (all saved, or none).
  SubmitReturnBatch: async (ctx, vars) => {
    requireRole(ctx.actor, SUBMITTER_ROLES);
    const branchId = reqId(vars, "branchId");
    const header = billHeader(vars);
    const lines = batchLines(vars).map(returnLine);
    const returnRecord_inserts = await submitLines(ctx, vars, branchId, header, lines);
    return { returnRecord_inserts };
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

