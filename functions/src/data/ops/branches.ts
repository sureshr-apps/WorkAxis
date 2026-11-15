import { denied } from "../../errors";
import { isOrgAdminOf, isPlatform, requireOrgAdminScope } from "../authz";
import type { OperationRegistry } from "../operation";
import { branchCols } from "../projections";
import { select, selectOne } from "../sql";
import { reqId } from "../vars";

type Row = Record<string, unknown>;

const BRANCH = branchCols("b");

/** Moves the flat `organizationId` column into `organization: { id }`. */
function nestOrganization(row: Row): Row {
  const { organizationId, ...rest } = row;
  return { ...rest, organization: { id: organizationId } };
}

// Branch creation/update (AddBranch, CreateBranch, UpdateBranch) were
// `@auth(level: NO_ACCESS)` server-only mutations; they live behind the
// branch-save callable and are intentionally not exposed here.
export const branchesOps: OperationRegistry = {
  ListBranchesByOrg: async ({ db, actor }, vars) => {
    const orgId = reqId(vars, "orgId");
    requireOrgAdminScope(actor, orgId);
    const branches = await select(
      db,
      `SELECT ${BRANCH} FROM branch b WHERE b.organization_id = $1 ORDER BY b.name ASC, b.id ASC`,
      [orgId],
    );
    return { branches };
  },

  // Org Admin: any branch of own org. Branch Manager/Employee: only branches
  // in their active set. Platform: any.
  GetBranchById: async ({ db, actor }, vars) => {
    const id = reqId(vars, "id");
    const row = await selectOne<Row>(
      db,
      `SELECT ${BRANCH}, b.organization_id AS "organizationId" FROM branch b WHERE b.id = $1`,
      [id],
    );
    const allowed =
      row !== null &&
      (isPlatform(actor) ||
        isOrgAdminOf(actor, row.organizationId as string) ||
        ((actor.role === "branchManager" || actor.role === "employee") &&
          actor.branchIds.includes(id)));
    if (!row || !allowed) throw denied("Branch not found or access denied.");
    return { branch: nestOrganization(row) };
  },

  // Only active branches are returned.
  ListMyBranchAssignments: async ({ db, actor }) => {
    const rows = await select<Row>(
      db,
      `SELECT a.id AS "assignmentId", ${BRANCH}, b.organization_id AS "organizationId"
         FROM user_branch_assignment a
         JOIN organization_member m ON m.id = a.member_id
         JOIN branch b ON b.id = a.branch_id
        WHERE m.auth_uid = $1 AND b.status = 'active'
        ORDER BY a.assigned_at ASC, a.id ASC`,
      [actor.uid],
    );
    const userBranchAssignments = rows.map(({ assignmentId, ...branch }) => ({
      id: assignmentId,
      branch: nestOrganization(branch),
    }));
    return { userBranchAssignments };
  },
};
