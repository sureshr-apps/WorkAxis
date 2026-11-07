import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import { denied } from "../errors";
import { getMemberByAuthUid, type MemberRecord } from "../sql/members";
import { type AccountStatus, type Actor, isPlatformRole } from "./roles";

/**
 * Resolves the caller from SQL (authoritative) rather than trusting token
 * claims, which can be up to an hour stale after a suspension or role change.
 */
export async function resolveActor(request: CallableRequest<unknown>): Promise<Actor> {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const member = await getMemberByAuthUid(uid);
  if (!member || member.status !== "active") throw denied();
  if (!isPlatformRole(member.role) && member.organizationStatus !== "active") {
    throw denied();
  }
  return {
    uid,
    role: member.role,
    organizationId: member.organizationId,
    branchIds: member.activeBranchIds,
  };
}

/** Claim/Auth status for a member: suspended if the member or its org is. */
export function effectiveStatus(member: MemberRecord): AccountStatus {
  if (member.status !== "active") return "suspended";
  if (!isPlatformRole(member.role) && member.organizationStatus !== "active") {
    return "suspended";
  }
  return "active";
}
