import type { Actor, Role } from "../auth/roles";
import { isPlatformRole } from "../auth/roles";
import type { MemberRecord } from "../sql/members";
import { invalid } from "../errors";

/**
 * Branch ids after an update. A Branch Manager only controls branches inside
 * their own scope, so assignments outside that scope are preserved.
 */
export function finalBranchIds(
  actor: Actor,
  existing: string[],
  requested: string[] | undefined,
  newRole: Role,
): string[] {
  if (newRole === "orgAdmin" || isPlatformRole(newRole)) return [];
  if (requested === undefined) return existing;
  const next =
    actor.role === "branchManager"
      ? [...existing.filter((b) => !actor.branchIds.includes(b)), ...requested]
      : requested;
  const unique = [...new Set(next)];
  if (unique.length === 0) throw invalid("At least one branch is required for this role.");
  return unique;
}

/** True if claims/session need a hard refresh (role or branch scope changed). */
export function scopeChanged(
  before: MemberRecord,
  role: Role,
  branchIds: string[],
): boolean {
  const a = [...before.branchIds].sort().join(",");
  const b = [...branchIds].sort().join(",");
  return before.role !== role || a !== b;
}
