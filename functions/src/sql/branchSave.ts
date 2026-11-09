import { sqlMutate, sqlQuery } from "./client";
import type { parseBranchSave, ManagerAssignment } from "../branches/savePlan";

type Plan = ReturnType<typeof parseBranchSave>;
type ManagerRow = Omit<ManagerAssignment, "branchIds" | "organizationId"> & {
  organization: { id: string };
  userBranchAssignments_on_member: { branch: { id: string } }[];
};

export async function loadBranchManagers(
  orgId: string,
): Promise<ManagerAssignment[]> {
  const result = await sqlQuery<{ organizationMembers: ManagerRow[] }>(
    `query Managers($orgId: String!) {
    organizationMembers(where: { organization: { id: { eq: $orgId } }, role: { eq: "branchManager" } }) {
      id authUid role organization { id }
      userBranchAssignments_on_member { branch { id } }
    }
  }`,
    { orgId },
  );
  return result.organizationMembers.map((m) => ({
    ...m,
    organizationId: m.organization.id,
    branchIds: m.userBranchAssignments_on_member.map((a) => a.branch.id),
  }));
}

/** Rechecks membership and last-branch invariants inside the write transaction. */
export async function commitBranchSave(plan: Plan, currentIds: string[]) {
  const wanted = plan.managerIds;
  const removed = currentIds.filter((id) => !wanted.includes(id));
  await sqlMutate(
    `mutation SaveBranch(
    $id: String!, $orgId: String!, $creating: Boolean!, $data: Branch_Data!,
    $wanted: [String!]!, $current: [String!]!, $removed: [String!]!
    ${wanted.length ? ", $assignments: [UserBranchAssignment_Data!]!" : ""}
  ) @transaction {
    query @check(expr: "vars.creating ? this.existing == null : (this.existing != null && this.existing.organization.id == vars.orgId)", message: "Branch not found.")
      @check(expr: "this.wanted.size() == vars.wanted.size() && this.wanted.all(m, m.authUid != null)", message: "Invalid manager selection.")
      @check(expr: "this.current.size() == vars.current.size() && this.current.all(a, a.member.id in vars.current)", message: "Assignments changed. Reload the branch.")
      @check(expr: "this.removed.all(m, m.userBranchAssignments_on_member.exists(a, a.branch.id != vars.id))", message: "A manager must keep at least one branch.") {
      existing: branch(id: $id) { organization { id } }
      wanted: organizationMembers(where: { id: { in: $wanted }, organization: { id: { eq: $orgId } }, role: { eq: "branchManager" } }) { id authUid }
      current: userBranchAssignments(where: { branch: { id: { eq: $id } }, member: { role: { eq: "branchManager" } } }) { member { id } }
      removed: organizationMembers(where: { id: { in: $removed } }) { userBranchAssignments_on_member { branch { id } } }
    }
    branch_upsert(data: $data)
    userBranchAssignment_deleteMany(where: { branch: { id: { eq: $id } }, member: { role: { eq: "branchManager" } } })
    ${wanted.length ? "userBranchAssignment_insertMany(data: $assignments)" : ""}
  }`,
    {
      id: plan.data.id,
      orgId: plan.data.organizationId,
      creating: plan.creating,
      data: plan.data,
      wanted,
      current: currentIds,
      removed,
      ...(wanted.length
        ? {
            assignments: wanted.map((memberId) => ({
              memberId,
              branchId: plan.data.id,
            })),
          }
        : {}),
    },
  );
}

export async function branchCreation(
  id: string,
): Promise<{
  id: string;
  code: string;
  creationFingerprint: string | null;
} | null> {
  const result = await sqlQuery<{
    branch: {
      id: string;
      code: string;
      creationFingerprint: string | null;
    } | null;
  }>(
    `query BranchCreation($id: String!) { branch(id: $id) { id code creationFingerprint } }`,
    { id },
  );
  return result.branch;
}
