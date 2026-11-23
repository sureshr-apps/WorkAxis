import type { SqlExecutor } from "../db/executor";
import { type BranchOrg, findBranchOrg } from "./projections";
import { type Actor, isPlatformRole, type Role } from "../auth/roles";
import { denied } from "../errors";
import { selectOne } from "./sql";
import { reqId } from "./vars";

const BRANCH_ACCESS_DENIED = "Branch not found or access denied.";

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
  if (!branch || !ok) throw denied(BRANCH_ACCESS_DENIED);
  return branch;
}

export interface ActiveBranch {
  id: string;
  name: string;
}

/** The branch when it exists, is active and belongs to [organizationId]; else null. */
export async function findActiveBranch(
  db: SqlExecutor,
  branchId: string,
  organizationId: string | undefined,
): Promise<ActiveBranch | null> {
  if (!organizationId) return null;
  return selectOne<ActiveBranch>(
    db,
    `SELECT id, name FROM branch WHERE id = $1 AND organization_id = $2 AND status = 'active' LIMIT 1`,
    [branchId, organizationId],
  );
}

/**
 * Like [findActiveBranch], but throws [error] when the branch is missing,
 * inactive or in another organization. Operations pass their established
 * error so the messages the app shows do not change.
 */
export async function requireActiveBranch(
  db: SqlExecutor,
  branchId: string,
  organizationId: string | undefined,
  error: () => Error = () => denied(BRANCH_ACCESS_DENIED),
): Promise<ActiveBranch> {
  const branch = await findActiveBranch(db, branchId, organizationId);
  if (!branch) throw error();
  return branch;
}

/**
 * Branch Managers act within their selected branch: `activeBranchId` must be
 * [branchId] and one of their assigned branches. Other roles are unaffected.
 */
export function requireBranchManagerContext(
  actor: Actor,
  vars: Record<string, unknown>,
  branchId: string,
  message = BRANCH_ACCESS_DENIED,
): void {
  if (actor.role !== "branchManager") return;
  const activeBranchId = reqId(vars, "activeBranchId");
  if (activeBranchId !== branchId || !actor.branchIds.includes(branchId)) {
    throw denied(message);
  }
}
