import { lastSignInTimes } from "../../accounts/signInTimes";
import { denied } from "../../errors";
import { optString } from "../../util/input";
import {
  isOrgAdminOf,
  isPlatform,
  requireOrgAdminScope,
  requirePlatform,
  requireManagedBranch,
} from "../authz";
import type { OperationRegistry } from "../operation";
import { MEMBER_LIST_FIELDS, memberCols, withMemberAssignments } from "../projections";
import { paged, Query, select, selectOne } from "../sql";
import { optText, pageVars, reqId } from "../vars";

type Row = Record<string, unknown>;

const LIST_COLS = memberCols("m", MEMBER_LIST_FIELDS);

const PLATFORM_ROLES = new Set(["platformOwner", "platformAdmin"]);

/**
 * Adds lastSignInAt to platform members, read from Firebase Auth (the only place
 * sign-ins are recorded). Other members are returned unchanged, so their sign-in
 * times are never exposed.
 */
async function withLastSignIn(members: Row[]): Promise<Row[]> {
  const platform = members.filter((m) => PLATFORM_ROLES.has(String(m.role)));
  if (platform.length === 0) return members;
  const times = await lastSignInTimes(platform.map((m) => String(m.authUid ?? "")));
  return members.map((m) =>
    PLATFORM_ROLES.has(String(m.role))
      ? { ...m, lastSignInAt: times.get(String(m.authUid ?? "")) ?? null }
      : m,
  );
}

// Data Connect `contains` was case-sensitive; here name filters use ILIKE with
// literal %/_ escaping so search is case-insensitive.
export const membersOps: OperationRegistry = {
  // The caller's own member record (role, org, status) for access resolution.
  GetMyMember: async ({ db, actor }) => {
    const rows = await select<Row>(
      db,
      `SELECT ${LIST_COLS},
              o.id AS "orgId", o.name AS "orgName", o.code AS "orgCode", o.status AS "orgStatus"
         FROM organization_member m
         LEFT JOIN organization o ON o.id = m.organization_id
        WHERE m.auth_uid = $1
        LIMIT 1`,
      [actor.uid],
    );
    const organizationMembers = rows.map(
      ({ orgId, orgName, orgCode, orgStatus, ...member }) => ({
        ...member,
        organization: orgId
          ? { id: orgId, name: orgName, code: orgCode, status: orgStatus }
          : null,
      }),
    );
    return { organizationMembers };
  },

  ListMembersByOrg: async ({ db, actor }, vars) => {
    const orgId = reqId(vars, "orgId");
    requireOrgAdminScope(actor, orgId);
    const organizationMembers = await select(
      db,
      `SELECT ${memberCols("m", ["id", "fullName", "username", "email", "phone", "role", "status"])}
         FROM organization_member m
        WHERE m.organization_id = $1
        ORDER BY m.full_name ASC, m.id ASC`,
      [orgId],
    );
    return { organizationMembers };
  },

  ListMembersByOrgPaged: async ({ db, actor }, vars) => {
    const orgId = reqId(vars, "orgId");
    requireOrgAdminScope(actor, orgId);
    const { limit, offset } = pageVars(vars);
    const q = new Query()
      .eq("m.organization_id", orgId)
      .contains("m.full_name", optText(vars, "nameContains", 200))
      .eq("m.status", optString(vars, "status", 1, 50))
      .eq("m.role", optString(vars, "role", 1, 50));
    const { rows, total } = await paged<Row>(db, {
      columns: LIST_COLS,
      from: "organization_member m",
      q,
      orderBy: "m.full_name ASC, m.id ASC",
      limit,
      offset,
    });
    return { organizationMembers: await withMemberAssignments(db, rows), total };
  },

  // Branch Manager view. Platform roles are deliberately excluded.
  ListMembersByBranchPaged: async ({ db, actor }, vars) => {
    const branchId = reqId(vars, "branchId");
    const { limit, offset } = pageVars(vars);
    await requireManagedBranch(db, actor, branchId);
    const q = new Query()
      .eq("a.branch_id", branchId)
      .contains("m.full_name", optText(vars, "nameContains", 200))
      .eq("m.status", optString(vars, "status", 1, 50))
      .eq(
        "m.role",
        // A branch manager lists only employees, never managers or themselves.
        actor.role === "branchManager" ? "employee" : optString(vars, "role", 1, 50),
      );
    const { rows, total } = await paged<Row>(db, {
      columns: memberCols("m", MEMBER_LIST_FIELDS),
      from: "user_branch_assignment a JOIN organization_member m ON m.id = a.member_id",
      q,
      orderBy: "a.assigned_at ASC, a.id ASC",
      limit,
      offset,
    });
    const members = await withMemberAssignments(db, rows);
    return { userBranchAssignments: members.map((member) => ({ member })), total };
  },

  // Platform: any. Org Admin: own org. Branch Manager: members sharing one of
  // their branches. Anyone: themselves.
  GetMemberById: async ({ db, actor }, vars) => {
    const id = reqId(vars, "id");
    const row = await selectOne<Row>(
      db,
      `SELECT ${memberCols("m", [...MEMBER_LIST_FIELDS, "createdAt"])},
              m.organization_id AS "organizationId"
         FROM organization_member m WHERE m.id = $1`,
      [id],
    );
    if (!row) throw denied("Member not found or access denied.");
    const [member] = await withMemberAssignments(db, [row], true);
    const assigned = (member.userBranchAssignments_on_member as { branch: { id: string } }[]).map(
      (a) => a.branch.id,
    );
    const allowed =
      row.authUid === actor.uid ||
      isPlatform(actor) ||
      isOrgAdminOf(actor, row.organizationId as string | null) ||
      (actor.role === "branchManager" && assigned.some((b) => actor.branchIds.includes(b)));
    if (!allowed) throw denied("Member not found or access denied.");
    const { organizationId, ...rest } = member;
    const [signedIn] = await withLastSignIn([rest]);
    return {
      organizationMember: { ...signedIn, organization: organizationId ? { id: organizationId } : null },
    };
  },

  // Platform administrators (SQL is authoritative; platform roles only).
  ListPlatformMembersPaged: async ({ db, actor }, vars) => {
    requirePlatform(actor);
    const { limit, offset } = pageVars(vars);
    const q = new Query()
      .and(`m.role = 'platformAdmin'`)
      .contains("m.full_name", optText(vars, "nameContains", 200))
      .eq("m.status", optString(vars, "status", 1, 50));
    const { rows, total } = await paged(db, {
      columns: memberCols("m", [...MEMBER_LIST_FIELDS, "createdAt"]),
      from: "organization_member m",
      q,
      orderBy: "m.created_at DESC, m.id DESC",
      limit,
      offset,
    });
    return { organizationMembers: await withLastSignIn(rows), total };
  },
};
