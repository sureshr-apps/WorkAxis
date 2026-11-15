import type { SqlExecutor } from "../db/executor";
import { type BranchOrg, findBranchOrg } from "./projections";
import { type Actor, isPlatformRole, type Role } from "../auth/roles";
import { denied } from "../errors";

export const isPlatform = (actor: Actor): boolean => isPlatformRole(actor.role);

export function requirePlatform(actor: Actor): void {
  if (!isPlatform(actor)) throw denied();
}

export function requireRole(actor: Actor, roles: readonly Role[]): void {
  if (!roles.includes(actor.role)) throw denied();
}

/** Platform roles for any organization; Org Admin only for their own. */
export function requireOrgAdminScope(actor: Actor, orgId: string): void {
  if (isPlatform(actor)) return;
  if (actor.role === "orgAdmin" && actor.organizationId === orgId) return;
  throw denied();
}

/** True when the actor is the Org Admin of the given organization. */
export function isOrgAdminOf(actor: Actor, orgId: string | null | undefined): boolean {
  return actor.role === "orgAdmin" && !!orgId && actor.organizationId === orgId;
}

/**
 * Branch-scoped manager operations: the branch must exist and be one the
 * actor administers (Org Admin of its org, or Branch Manager assigned to it).
 * Platform roles are deliberately excluded, as in the original @check rules.
 */
export async function requireManagedBranch(
  db: SqlExecutor,
  actor: Actor,
  branchId: string,
): Promise<BranchOrg> {
  const branch = await findBranchOrg(db, branchId);
  const ok =
    branch !== null &&
    (isOrgAdminOf(actor, branch.organizationId) ||
      (actor.role === "branchManager" && actor.branchIds.includes(branchId)));
  if (!branch || !ok) throw denied("Branch not found or access denied.");
  return branch;
}
