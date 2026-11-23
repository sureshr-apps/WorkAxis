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
 * Re-projects SQL state onto the Firestore profile, Auth claims and sign-in
 * state. `revoke` forces existing sessions to refresh their token.
 *
 * The profile is written first: security rules check it on every request, so
 * a suspension or branch removal takes effect immediately, while an issued ID
 * token would keep its old claims for up to an hour.
 */
export async function refreshProjection(member: MemberRecord, revoke = false): Promise<void> {
  const status = effectiveStatus(member);
  await writeProfile(member);
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
}
