import { getDb, isUniqueViolation, type SqlExecutor } from "../db";
import { conflict } from "../errors";
import { validateEmployeeCode } from "../util/employeeProfile";
import type { AccountStatus, Role } from "../auth/roles";

export interface MemberRecord {
  id: string;
  authUid: string;
  fullName: string;
  username: string;
  email: string;
  phone?: string;
  role: Role;
  status: AccountStatus;
  /** Per-organization employee ID; SQL is authoritative. */
  employeeCode?: string;
  organizationId?: string;
  organizationStatus?: string;
  branchIds: string[];
  /** Branch ids whose branch row is active. */
  activeBranchIds: string[];
}

interface MemberRow {
  id: string;
  authUid: string;
  fullName: string;
  username: string;
  email: string;
  phone: string | null;
  role: Role;
  status: AccountStatus;
  employeeCode: string | null;
  organizationId: string | null;
  organizationStatus: string | null;
}

interface AssignmentRow {
  memberId: string;
  branchId: string;
  branchStatus: string;
}

const MEMBER_SELECT = `
  SELECT m.id, m.auth_uid AS "authUid", m.full_name AS "fullName", m.username,
         m.email, m.phone, m.role, m.status, m.employee_code AS "employeeCode",
         o.id AS "organizationId", o.status AS "organizationStatus"
    FROM organization_member m
    LEFT JOIN organization o ON o.id = m.organization_id`;

async function loadMembers(
  db: SqlExecutor,
  where: string,
  params: unknown[],
): Promise<MemberRecord[]> {
  const rows = await db.query<MemberRow>(
    `${MEMBER_SELECT} WHERE ${where} ORDER BY m.created_at, m.id`,
    params,
  );
  if (rows.length === 0) return [];
  const assignments = await db.query<AssignmentRow>(
    `SELECT a.member_id AS "memberId", b.id AS "branchId", b.status AS "branchStatus"
       FROM user_branch_assignment a
       JOIN branch b ON b.id = a.branch_id
      WHERE a.member_id = ANY($1::text[])
      ORDER BY a.assigned_at, b.id`,
    [rows.map((r) => r.id)],
  );
  return rows.map((r) =>
    toRecord(
      r,
      assignments.filter((a) => a.memberId === r.id),
    ),
  );
}

function toRecord(r: MemberRow, branches: AssignmentRow[]): MemberRecord {
  return {
    id: r.id,
    authUid: r.authUid,
    fullName: r.fullName,
    username: r.username,
    email: r.email,
    phone: r.phone ?? undefined,
    role: r.role,
    status: r.status,
    employeeCode: r.employeeCode ?? undefined,
    organizationId: r.organizationId ?? undefined,
    organizationStatus: r.organizationStatus ?? undefined,
    branchIds: branches.map((b) => b.branchId),
    activeBranchIds: branches
      .filter((b) => b.branchStatus === "active")
      .map((b) => b.branchId),
  };
}

export async function getMemberByAuthUid(
  uid: string,
): Promise<MemberRecord | null> {
  const db = await getDb();
  const rows = await loadMembers(db, "m.auth_uid = $1", [uid]);
  return rows[0] ?? null;
}

export async function listMembersOfOrganization(
  orgId: string,
): Promise<MemberRecord[]> {
  const db = await getDb();
  const rows = await loadMembers(db, "m.organization_id = $1", [orgId]);
  return rows.filter((m) => m.authUid);
}

export interface NewMember {
  id: string;
  authUid: string;
  organizationId?: string;
  fullName: string;
  username: string;
  email: string;
  phone?: string;
  role: Role;
  /** Manual employee ID; when absent one is allocated from the organization sequence. */
  employeeCode?: string;
}

const MEMBER_INSERT_COLUMNS: ReadonlyArray<[keyof NewMember, string]> = [
  ["id", "id"],
  ["authUid", "auth_uid"],
  ["organizationId", "organization_id"],
  ["fullName", "full_name"],
  ["username", "username"],
  ["email", "email"],
  ["phone", "phone"],
  ["role", "role"],
  ["employeeCode", "employee_code"],
];

const EMPLOYEE_CODE_INDEX = "organization_member_org_employee_code_uq";
const MAX_ALLOCATION_ATTEMPTS = 50;

/** Maps an employee-code unique violation to a client-safe conflict. */
function mapEmployeeCodeError(e: unknown): unknown {
  if (!isUniqueViolation(e)) return e;
  const detail = e as { constraint?: string; message?: string };
  if (
    detail.constraint === EMPLOYEE_CODE_INDEX ||
    detail.message?.includes(EMPLOYEE_CODE_INDEX)
  ) {
    return conflict("That employee ID is already in use.");
  }
  return e;
}

/**
 * Atomically takes the next 'EMP-n' from the organization's counter. Must run
 * inside the member-insert transaction so a rollback returns the number.
 * Skips codes already taken manually.
 */
async function allocateEmployeeCode(tx: SqlExecutor, organizationId: string): Promise<string> {
  for (let attempt = 0; attempt < MAX_ALLOCATION_ATTEMPTS; attempt++) {
    const rows = await tx.query<{ employee_code_seq: number }>(
      `UPDATE organization SET employee_code_seq = employee_code_seq + 1
        WHERE id = $1 RETURNING employee_code_seq`,
      [organizationId],
    );
    if (rows.length === 0) throw new Error("Organization not found for employee code.");
    const code = `EMP-${rows[0].employee_code_seq}`;
    const taken = await tx.query(
      `SELECT 1 FROM organization_member WHERE organization_id = $1 AND employee_code = $2`,
      [organizationId, code],
    );
    if (taken.length === 0) return code;
  }
  throw new Error("Could not allocate an employee code.");
}

async function insertAssignments(
  tx: SqlExecutor,
  memberId: string,
  branchIds: string[],
): Promise<void> {
  if (branchIds.length === 0) return;
  await tx.query(
    `INSERT INTO user_branch_assignment (member_id, branch_id)
     SELECT $1, unnest($2::text[])`,
    [memberId, branchIds],
  );
}

/**
 * Inserts the member and its branch assignments in one SQL transaction.
 * Returns the employee code stored for the member (allocated when none was
 * supplied and the member belongs to an organization).
 */
export async function insertMember(
  member: NewMember,
  branchIds: string[],
): Promise<string | undefined> {
  // Employee IDs are per organization; platform roles have none.
  const manualCode =
    member.employeeCode === undefined || !member.organizationId
      ? undefined
      : validateEmployeeCode(member.employeeCode);
  const db = await getDb();
  try {
    return await db.transaction(async (tx) => {
      const employeeCode =
        manualCode ??
        (member.organizationId ? await allocateEmployeeCode(tx, member.organizationId) : undefined);
      const row: NewMember = { ...member, employeeCode };
      const cols = MEMBER_INSERT_COLUMNS.filter(([k]) => row[k] !== undefined);
      const values = cols.map(([k]) => row[k]);
      await insertRow(tx, cols, values);
      await insertAssignments(tx, member.id, branchIds);
      return employeeCode;
    });
  } catch (e) {
    throw mapEmployeeCodeError(e);
  }
}

async function insertRow(
  tx: SqlExecutor,
  cols: ReadonlyArray<[keyof NewMember, string]>,
  values: unknown[],
): Promise<void> {
  await tx.query(
    `INSERT INTO organization_member (${cols.map(([, c]) => c).join(", ")}, status)
     VALUES (${values.map((_, i) => `$${i + 1}`).join(", ")}, 'active')`,
    values,
  );
}

export interface MemberPatch {
  fullName?: string;
  email?: string;
  phone?: string | null;
  role?: Role;
  status?: AccountStatus;
  employeeCode?: string;
}

const PATCH_COLUMNS: ReadonlyArray<[keyof MemberPatch, string]> = [
  ["fullName", "full_name"],
  ["email", "email"],
  ["phone", "phone"],
  ["role", "role"],
  ["status", "status"],
  ["employeeCode", "employee_code"],
];

async function applyPatch(
  tx: SqlExecutor,
  memberId: string,
  patch: MemberPatch,
): Promise<void> {
  const cols = PATCH_COLUMNS.filter(([k]) => patch[k] !== undefined);
  if (cols.length === 0) return;
  if (patch.employeeCode !== undefined) {
    patch = { ...patch, employeeCode: validateEmployeeCode(patch.employeeCode) };
  }
  try {
    await tx.query(
      `UPDATE organization_member
          SET ${cols.map(([, c], i) => `${c} = $${i + 2}`).join(", ")}
        WHERE id = $1`,
      [memberId, ...cols.map(([k]) => patch[k])],
    );
  } catch (e) {
    throw mapEmployeeCodeError(e);
  }
}

export async function updateMember(
  memberId: string,
  patch: MemberPatch,
): Promise<void> {
  await applyPatch(await getDb(), memberId, patch);
}

async function clearAssignments(
  tx: SqlExecutor,
  memberId: string,
): Promise<void> {
  await tx.query(`DELETE FROM user_branch_assignment WHERE member_id = $1`, [
    memberId,
  ]);
}

/** Replaces all branch assignments for a member atomically. */
export async function replaceBranchAssignments(
  memberId: string,
  branchIds: string[],
): Promise<void> {
  const db = await getDb();
  await db.transaction(async (tx) => {
    await clearAssignments(tx, memberId);
    await insertAssignments(tx, memberId, branchIds);
  });
}

/** Compensation: removes a partially provisioned member. */
export async function deleteMemberByAuthUid(uid: string): Promise<void> {
  const db = await getDb();
  await db.transaction(async (tx) => {
    await tx.query(
      `DELETE FROM user_branch_assignment
        WHERE member_id IN (SELECT id FROM organization_member WHERE auth_uid = $1)`,
      [uid],
    );
    await tx.query(`DELETE FROM organization_member WHERE auth_uid = $1`, [uid]);
  });
}

/** Member fields and assignments commit together, so failed edits leave neither half updated. */
export async function updateMemberWithAssignments(
  memberId: string,
  patch: MemberPatch,
  branchIds: string[],
): Promise<void> {
  const db = await getDb();
  await db.transaction(async (tx) => {
    await applyPatch(tx, memberId, patch);
    await clearAssignments(tx, memberId);
    await insertAssignments(tx, memberId, branchIds);
  });
}
