import type { AccountStatus, Role } from "../auth/roles";
import { sqlMutate, sqlQuery } from "./client";

export interface MemberRecord {
  id: string;
  authUid: string;
  fullName: string;
  username: string;
  email: string;
  phone?: string;
  role: Role;
  status: AccountStatus;
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
  phone?: string | null;
  role: Role;
  status: AccountStatus;
  organization?: { id: string; status: string } | null;
  userBranchAssignments_on_member: { branch: { id: string; status: string } }[];
}

const MEMBER_FIELDS = `
  id authUid fullName username email phone role status
  organization { id status }
  userBranchAssignments_on_member { branch { id status } }
`;

function toRecord(r: MemberRow): MemberRecord {
  const branches = r.userBranchAssignments_on_member.map((a) => a.branch);
  return {
    id: r.id,
    authUid: r.authUid,
    fullName: r.fullName,
    username: r.username,
    email: r.email,
    phone: r.phone ?? undefined,
    role: r.role,
    status: r.status,
    organizationId: r.organization?.id,
    organizationStatus: r.organization?.status,
    branchIds: branches.map((b) => b.id),
    activeBranchIds: branches
      .filter((b) => b.status === "active")
      .map((b) => b.id),
  };
}

export async function getMemberByAuthUid(
  uid: string,
): Promise<MemberRecord | null> {
  const data = await sqlQuery<{ organizationMembers: MemberRow[] }>(
    `query MemberByAuthUid($uid: String!) {
       organizationMembers(where: { authUid: { eq: $uid } }, limit: 1) { ${MEMBER_FIELDS} }
     }`,
    { uid },
  );
  const row = data.organizationMembers[0];
  return row ? toRecord(row) : null;
}

export async function listMembersOfOrganization(
  orgId: string,
): Promise<MemberRecord[]> {
  const data = await sqlQuery<{ organizationMembers: MemberRow[] }>(
    `query MembersOfOrg($orgId: String!) {
       organizationMembers(where: { organization: { id: { eq: $orgId } } }) { ${MEMBER_FIELDS} }
     }`,
    { orgId },
  );
  return data.organizationMembers.filter((m) => m.authUid).map(toRecord);
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
}

/** Inserts the member and its branch assignments in one SQL transaction. */
export async function insertMember(
  member: NewMember,
  branchIds: string[],
): Promise<void> {
  const data: Record<string, unknown> = { ...member, status: "active" };
  for (const k of Object.keys(data)) if (data[k] === undefined) delete data[k];

  if (branchIds.length === 0) {
    await sqlMutate(
      `mutation InsertMember($member: OrganizationMember_Data!) {
         organizationMember_insert(data: $member)
       }`,
      { member: data },
    );
    return;
  }
  await sqlMutate(
    `mutation InsertMemberWithBranches(
       $member: OrganizationMember_Data!
       $assignments: [UserBranchAssignment_Data!]!
     ) @transaction {
       organizationMember_insert(data: $member)
       userBranchAssignment_insertMany(data: $assignments)
     }`,
    {
      member: data,
      assignments: branchIds.map((branchId) => ({
        memberId: member.id,
        branchId,
      })),
    },
  );
}

export interface MemberPatch {
  fullName?: string;
  email?: string;
  phone?: string | null;
  role?: Role;
  status?: AccountStatus;
}

export async function updateMember(
  memberId: string,
  patch: MemberPatch,
): Promise<void> {
  const data: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(patch)) if (v !== undefined) data[k] = v;
  if (Object.keys(data).length === 0) return;
  await sqlMutate(
    `mutation UpdateMember($id: String!, $data: OrganizationMember_Data!) {
       organizationMember_update(id: $id, data: $data)
     }`,
    { id: memberId, data },
  );
}

/** Replaces all branch assignments for a member atomically. */
export async function replaceBranchAssignments(
  memberId: string,
  branchIds: string[],
): Promise<void> {
  if (branchIds.length === 0) {
    await sqlMutate(
      `mutation ClearAssignments($memberId: String!) {
         userBranchAssignment_deleteMany(where: { member: { id: { eq: $memberId } } })
       }`,
      { memberId },
    );
    return;
  }
  await sqlMutate(
    `mutation ReplaceAssignments($memberId: String!, $assignments: [UserBranchAssignment_Data!]!) @transaction {
       userBranchAssignment_deleteMany(where: { member: { id: { eq: $memberId } } })
       userBranchAssignment_insertMany(data: $assignments)
     }`,
    {
      memberId,
      assignments: branchIds.map((branchId) => ({ memberId, branchId })),
    },
  );
}

/** Compensation: removes a partially provisioned member. */
export async function deleteMemberByAuthUid(uid: string): Promise<void> {
  await sqlMutate(
    `mutation DeleteMemberByUid($uid: String!) @transaction {
       userBranchAssignment_deleteMany(where: { member: { authUid: { eq: $uid } } })
       organizationMember_deleteMany(where: { authUid: { eq: $uid } })
     }`,
    { uid },
  );
}

/** Member fields and assignments commit together, so failed edits leave neither half updated. */
export async function updateMemberWithAssignments(
  memberId: string,
  patch: MemberPatch,
  branchIds: string[],
): Promise<void> {
  const inserts = branchIds.length
    ? "userBranchAssignment_insertMany(data: $assignments)"
    : "";
  const declaration = branchIds.length
    ? ", $assignments: [UserBranchAssignment_Data!]!"
    : "";
  await sqlMutate(
    `mutation UpdateAccount($id: String!, $data: OrganizationMember_Data!${declaration}) @transaction {
    organizationMember_update(id: $id, data: $data)
    userBranchAssignment_deleteMany(where: { member: { id: { eq: $id } } })
    ${inserts}
  }`,
    {
      id: memberId,
      data: patch,
      ...(branchIds.length
        ? {
            assignments: branchIds.map((branchId) => ({ memberId, branchId })),
          }
        : {}),
    },
  );
}
