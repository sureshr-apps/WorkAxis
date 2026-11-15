import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import { denied } from "../errors";
import { getMemberByAuthUid, type MemberRecord } from "../sql/members";
import { ACCESS_ISSUE_MESSAGES, accessIssueFor } from "./accessIssues";
import { type AccountStatus, type Actor, isPlatformRole } from "./roles";

/**
 * Resolves the caller from SQL (authoritative) rather than trusting token
 * claims, which can be up to an hour stale after a suspension or role change.
 * A refused caller gets the specific reason (see accessIssues.ts).
 */
export async function resolveActor(request: CallableRequest<unknown>): Promise<Actor> {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const member = await getMemberByAuthUid(uid);
  if (!member) throw denied();
  const issue = accessIssueFor(member, member.licenseToday);
  if (issue) throw denied(ACCESS_ISSUE_MESSAGES[issue]);
  return {
    uid,
    role: member.role,
    organizationId: member.organizationId,
    branchIds: member.activeBranchIds,
  };
}

/**
 * Platform roles are not tied to a customer organization. Every other member
 * needs an active organization that holds a usable license.
 */
function hasOrganizationAccess(member: MemberRecord): boolean {
  if (isPlatformRole(member.role)) return true;
  return member.organizationStatus === "active" && member.licenseUsable;
}

/** Claim/Auth status for a member: suspended if the member, its org or its org's license is not usable. */
export function effectiveStatus(member: MemberRecord): AccountStatus {
  if (member.status !== "active") return "suspended";
  return hasOrganizationAccess(member) ? "active" : "suspended";
}
