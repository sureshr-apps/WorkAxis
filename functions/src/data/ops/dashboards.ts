import { requireManagedBranch, requireOrgAdminScope } from "../authz";
import type { OperationRegistry } from "../operation";
import { countRows, groupRows, Query } from "../sql";
import { optTimestamp, reqId } from "../vars";

export const dashboardsOps: OperationRegistry = {
  // Org dashboard counts: branches and members by status, returns by status.
  GetOrganizationDashboardCounts: async ({ db, actor }, vars) => {
    const orgId = reqId(vars, "orgId");
    requireOrgAdminScope(actor, orgId);
    const branchesByStatus = await groupRows(
      db,
      `SELECT status, count(*)::int AS "_count" FROM branch
        WHERE organization_id = $1 GROUP BY status ORDER BY status`,
      [orgId],
    );
    const membersByRole = await groupRows(
      db,
      `SELECT role, status, count(*)::int AS "_count" FROM organization_member
        WHERE organization_id = $1 GROUP BY role, status ORDER BY role, status`,
      [orgId],
    );
    const returnsByStatus = await groupRows(
      db,
      `SELECT status, count(*)::int AS "_count" FROM return_record
        WHERE organization_id = $1 GROUP BY status ORDER BY status`,
      [orgId],
    );
    return { branchesByStatus, membersByRole, returnsByStatus };
  },

  // Optional $from (inclusive) / $to (exclusive) scope the counts to a period.
  GetReturnCountsByBranch: async ({ db, actor }, vars) => {
    const orgId = reqId(vars, "orgId");
    requireOrgAdminScope(actor, orgId);
    const from = optTimestamp(vars, "from");
    const to = optTimestamp(vars, "to");
    const q = new Query().eq("organization_id", orgId).period("created_at", from, to);
    const returnRecords = await groupRows(
      db,
      `SELECT branch_id AS "branchId", status, count(*)::int AS "_count"
         FROM return_record ${q.where} GROUP BY branch_id, status ORDER BY branch_id, status`,
      q.params,
    );
    const returnsByReason = await groupRows(
      db,
      `SELECT return_reason AS "returnReason", count(*)::int AS "_count"
         FROM return_record ${q.where} GROUP BY return_reason ORDER BY return_reason`,
      q.params,
    );
    return { returnRecords, returnsByReason };
  },

  // Branch dashboard counts: assigned active employees and returns by status.
  GetBranchStats: async ({ db, actor }, vars) => {
    const branchId = reqId(vars, "branchId");
    await requireManagedBranch(db, actor, branchId);
    const from = optTimestamp(vars, "from");
    const to = optTimestamp(vars, "to");
    const memberCount = await countRows(
      db,
      `SELECT count(*)::int AS "_count"
         FROM user_branch_assignment a
         JOIN organization_member m ON m.id = a.member_id
        WHERE a.branch_id = $1 AND m.role = 'employee' AND m.status = 'active'`,
      [branchId],
    );
    const q = new Query().eq("branch_id", branchId).period("created_at", from, to);
    const returnsByStatus = await groupRows(
      db,
      `SELECT status, count(*)::int AS "_count"
         FROM return_record ${q.where} GROUP BY status ORDER BY status`,
      q.params,
    );
    const returnsByReason = await groupRows(
      db,
      `SELECT return_reason AS "returnReason", count(*)::int AS "_count"
         FROM return_record ${q.where} GROUP BY return_reason ORDER BY return_reason`,
      q.params,
    );
    return { memberCount, returnsByStatus, returnsByReason };
  },
};
