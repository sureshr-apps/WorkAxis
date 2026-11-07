import { notFound } from "../errors";
import { getMemberByAuthUid, type MemberRecord } from "../sql/members";
import type { Target } from "../auth/roles";
import { effectiveStatus } from "../auth/actor";
import { applyClaims, buildClaims, setSignInState } from "../auth/claims";
import { writeProfile } from "../firestore/userStore";
import { getAuth } from "firebase-admin/auth";

export async function loadTarget(
  targetUid: string,
): Promise<{ member: MemberRecord; target: Target }> {
  const member = await getMemberByAuthUid(targetUid);
  if (!member) throw notFound("Account not found.");
  return {
    member,
    target: {
      uid: targetUid,
      role: member.role,
      organizationId: member.organizationId,
      branchIds: member.branchIds,
    },
  };
}

/**
 * Re-projects SQL state onto Auth claims, sign-in state and the Firestore
 * profile. `revoke` forces existing sessions to refresh their token.
 */
export async function refreshProjection(member: MemberRecord, revoke = false): Promise<void> {
  const status = effectiveStatus(member);
  await applyClaims(
    member.authUid,
    buildClaims({
      role: member.role,
      organizationId: member.organizationId,
      branchIds: member.activeBranchIds,
      status,
    }),
  );
  await setSignInState(member.authUid, status);
  if (revoke && status === "active") await getAuth().revokeRefreshTokens(member.authUid);
  await writeProfile(member);
}
