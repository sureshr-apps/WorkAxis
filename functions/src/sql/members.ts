import { getDb, isUniqueViolation, type SqlExecutor } from "../db";
import { conflict, precondition } from "../errors";
import { LICENSE_TODAY_SQL } from "../licenses/licenseStatus";
import { validateEmployeeCode } from "../util/employeeProfile";
import type { AccountStatus, Role } from "../auth/roles";
import { assertMemberAllowed } from "./licenses";

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
  /**
   * The organization has a license whose plan is active and whose dates include
   * today (Asia/Kolkata). Always false for members without an organization.
   */
  licenseUsable: boolean;
  /** The organization's license dates (YYYY-MM-DD) and plan status; absent when there is no license. */
  licenseStartDate?: string;
  licenseExpiryDate?: string;
  licensePlanStatus?: string;
  /** Today's date in the license time zone, as SQL evaluated it for this read (YYYY-MM-DD). */
  licenseToday: string;
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
  licenseUsable: boolean | null;
  licenseStartDate: string | null;
  licenseExpiryDate: string | null;
  licensePlanStatus: string | null;
  licenseToday: string;
}

interface AssignmentRow {
  memberId: string;
  branchId: string;
  branchStatus: string;
}

const MEMBER_SELECT = `
  SELECT m.id, m.auth_uid AS "authUid", m.full_name AS "fullName", m.username,
         m.email, m.phone, m.role, m.status, m.employee_code AS "employeeCode",
         o.id AS "organizationId", o.status AS "organizationStatus",
         COALESCE(lp.status = 'active'
                  AND ol.start_date <= ${LICENSE_TODAY_SQL}
                  AND ol.expiry_date >= ${LICENSE_TODAY_SQL}, false) AS "licenseUsable",
         to_char(ol.start_date, 'YYYY-MM-DD') AS "licenseStartDate",
         to_char(ol.expiry_date, 'YYYY-MM-DD') AS "licenseExpiryDate",
         lp.status AS "licensePlanStatus",
         to_char(${LICENSE_TODAY_SQL}, 'YYYY-MM-DD') AS "licenseToday"
    FROM organization_member m
    LEFT JOIN organization o ON o.id = m.organization_id
    LEFT JOIN organization_license ol ON ol.organization_id = o.id
    LEFT JOIN license_plan lp ON lp.id = ol.plan_id`;

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
    licenseUsable: r.licenseUsable === true,
    licenseStartDate: r.licenseStartDate ?? undefined,
    licenseExpiryDate: r.licenseExpiryDate ?? undefined,
    licensePlanStatus: r.licensePlanStatus ?? undefined,
    licenseToday: r.licenseToday,
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

export interface InitialMemberWorkforce {
  createdByUid?: string;
  effectiveFrom?: string;
  dailyWorkHours?: number;
  shiftHours?: string;
  weeklyDayOff?: number;
  monthlySalary?: number | null;
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
    `INSERT INTO user_branch_assignment (member_id, branch_id, assigned_at)
     SELECT $1, unnest($2::text[]), now()`,
    [memberId, branchIds],
  );
}

async function requireActiveOrganizationForProvision(
  tx: SqlExecutor,
  organizationId: string,
): Promise<void> {
  // Serialize member creation against organization suspension. If creation
  // acquires this lock first, deletion waits and then lists the committed user;
  // if deletion suspends first, this transaction observes it and aborts.
  const [organization] = await tx.query<{ status: string }>(
    `SELECT status FROM organization WHERE id = $1 FOR UPDATE`,
    [organizationId],
  );
  if (!organization || organization.status !== "active") {
    throw precondition("Organization is not active.");
  }
}

/**
 * Inserts the member and its branch assignments in one SQL transaction.
 * Returns the employee code stored for the member (allocated when none was
 * supplied and the member belongs to an organization).
 */
export async function insertMember(
  member: NewMember,
  branchIds: string[],
  workforce?: InitialMemberWorkforce,
): Promise<string | undefined> {
  // Employee IDs are per organization; platform roles have none.
  const manualCode =
    member.employeeCode === undefined || !member.organizationId
      ? undefined
      : validateEmployeeCode(member.employeeCode);
  const db = await getDb();
  try {
    return await db.transaction(async (tx) => {
      if (member.organizationId) {
        await requireActiveOrganizationForProvision(tx, member.organizationId);
        // Adding an active member is refused at the plan's user limit, under the license row lock.
        await assertMemberAllowed(tx, member.organizationId, null);
      }
      const employeeCode =
        manualCode ??
        (member.organizationId ? await allocateEmployeeCode(tx, member.organizationId) : undefined);
      const row: NewMember = { ...member, employeeCode };
      const cols = MEMBER_INSERT_COLUMNS.filter(([k]) => row[k] !== undefined);
      const values = cols.map(([k]) => row[k]);
      await insertRow(tx, cols, values);
      await insertAssignments(tx, member.id, branchIds);
      if (workforce && (member.role === "employee" || member.role === "branchManager")) {
        const today = new Intl.DateTimeFormat("en-CA", {
          timeZone: "Asia/Kolkata",
          year: "numeric",
          month: "2-digit",
          day: "2-digit",
        }).format(new Date());
        const effectiveFrom = workforce.effectiveFrom ?? today;
        await tx.query(
          `INSERT INTO employee_schedule_history
            (member_id, effective_from, daily_work_hours, shift_hours, weekly_day_off, created_by_uid)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            member.id,
            effectiveFrom,
            workforce.dailyWorkHours ?? 8,
            workforce.shiftHours ?? "09:00 AM - 05:00 PM",
            workforce.weeklyDayOff ?? 0,
            workforce.createdByUid ?? null,
          ],
        );
        if (workforce.monthlySalary !== undefined && workforce.monthlySalary !== null) {
          await tx.query(
            `INSERT INTO employee_compensation_history
              (member_id, effective_from, monthly_salary, created_by_uid)
             VALUES ($1, $2, $3, $4)`,
            [member.id, effectiveFrom, workforce.monthlySalary, workforce.createdByUid ?? null],
          );
        }
      }
      return employeeCode;
    });
  } catch (e) {
    throw mapEmployeeCodeError(e);
  }
}

// created_at is written explicitly: the live table came from Data Connect, whose
// @default(expr: "request.time") was applied outside the database, so the column
// has no SQL default and an omitted value violates NOT NULL.
async function insertRow(
  tx: SqlExecutor,
  cols: ReadonlyArray<[keyof NewMember, string]>,
  values: unknown[],
): Promise<void> {
  await tx.query(
    `INSERT INTO organization_member (${cols.map(([, c]) => c).join(", ")}, status, created_at)
     VALUES (${values.map((_, i) => `$${i + 1}`).join(", ")}, 'active', now())`,
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

/**
 * Reactivating a suspended member counts against the plan's user limit. A member
 * that is already active is not counted again.
 */
async function assertCanActivate(tx: SqlExecutor, memberId: string): Promise<void> {
  const [current] = await tx.query<{ organizationId: string | null; status: AccountStatus }>(
    `SELECT organization_id AS "organizationId", status FROM organization_member WHERE id = $1`,
    [memberId],
  );
  if (!current || current.status === "active" || !current.organizationId) return;
  await assertMemberAllowed(tx, current.organizationId, memberId);
}

/** Applies a patch; a status change to active is capacity-checked in the same transaction. */
async function applyGuardedPatch(
  tx: SqlExecutor,
  memberId: string,
  patch: MemberPatch,
): Promise<void> {
  if (patch.status === "active") await assertCanActivate(tx, memberId);
  await applyPatch(tx, memberId, patch);
}

export async function updateMember(
  memberId: string,
  patch: MemberPatch,
): Promise<void> {
  const db = await getDb();
  await db.transaction((tx) => applyGuardedPatch(tx, memberId, patch));
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
    await applyGuardedPatch(tx, memberId, patch);
    await clearAssignments(tx, memberId);
    await insertAssignments(tx, memberId, branchIds);
  });
}
