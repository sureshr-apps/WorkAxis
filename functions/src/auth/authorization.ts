import { denied, invalid } from "../errors";
import { type Actor, type Role, type Target, isPlatformRole } from "./roles";

/**
 * Authorization matrix for identity operations. Pure functions: no I/O, so
 * the whole matrix is unit-testable. Each throws DomainError on denial.
 *
 * Creation matrix:
 *   platformOwner  -> platformAdmin, orgAdmin (any org)
 *   platformAdmin  -> orgAdmin (any org)
 *   orgAdmin       -> orgAdmin | branchManager | employee (own org)
 *   branchManager  -> employee in branches within own branchIds
 *   employee       -> nobody;  nobody creates platformOwner
 */
export function assertCanProvision(actor: Actor, target: Target): void {
  assertShape(target);
  switch (target.role) {
    case "platformOwner":
      throw denied("Platform Owner accounts cannot be created.");
    case "platformAdmin":
      if (actor.role !== "platformOwner") {
        throw denied("Only the Platform Owner can create Platform Administrators.");
      }
      return;
    case "orgAdmin":
      if (isPlatformRole(actor.role)) return;
      if (actor.role === "orgAdmin" && sameOrg(actor, target)) return;
      throw denied();
    case "branchManager":
      if (actor.role === "orgAdmin" && sameOrg(actor, target)) return;
      throw denied();
    case "employee":
      if (actor.role === "orgAdmin" && sameOrg(actor, target)) return;
      if (
        actor.role === "branchManager" &&
        sameOrg(actor, target) &&
        target.branchIds.every((b) => actor.branchIds.includes(b))
      ) {
        return;
      }
      throw denied();
  }
}

export type ManageOperation = "update" | "resetPassword" | "setStatus";

export interface ManageChange {
  role?: Role;
  branchIds?: string[];
}

/**
 * Whether `actor` may manage the existing account `target`.
 * Self-service role/status/branch changes are never allowed here.
 */
export function assertCanManage(
  actor: Actor,
  target: Target,
  op: ManageOperation,
  change: ManageChange = {},
): void {
  if (target.role === "platformOwner") throw denied();
  const isSelf = target.uid !== undefined && target.uid === actor.uid;
  if (isSelf && (op === "setStatus" || change.role || change.branchIds)) {
    throw denied("You cannot change your own role, branches or status.");
  }
  if (!isSelf && !canReach(actor, target)) throw denied();
  if (isSelf && actor.role === "employee") throw denied();

  if (change.role !== undefined && change.role !== target.role) {
    // Role changes never cross the platform/customer boundary.
    if (isPlatformRole(change.role) !== isPlatformRole(target.role)) throw denied();
    assertCanProvision(actor, {
      role: change.role,
      organizationId: target.organizationId,
      branchIds: change.branchIds ?? target.branchIds,
    });
  }
  if (change.branchIds !== undefined && actor.role === "branchManager") {
    // A Branch Manager can only grant branches inside their own scope.
    if (!change.branchIds.every((b) => actor.branchIds.includes(b))) {
      throw denied("You can only assign branches you manage.");
    }
  }
}

function canReach(actor: Actor, target: Target): boolean {
  switch (actor.role) {
    case "platformOwner":
      return target.role === "platformAdmin" || target.role === "orgAdmin";
    case "platformAdmin":
      return target.role === "orgAdmin";
    case "orgAdmin":
      return (
        target.role !== "platformAdmin" &&
        target.role !== "platformOwner" &&
        sameOrg(actor, target)
      );
    case "branchManager":
      return (
        target.role === "employee" &&
        sameOrg(actor, target) &&
        target.branchIds.some((b) => actor.branchIds.includes(b))
      );
    case "employee":
      return false;
  }
}

/**
 * Deleting a Platform Administrator is a Platform Owner decision. The owner
 * cannot delete their own account, and this rule covers only platform
 * administrators (customer accounts are removed through their own flows).
 */
export function assertCanDeletePlatformAdministrator(actor: Actor, target: Target): void {
  if (actor.role !== "platformOwner") {
    throw denied("Only the Platform Owner can delete Platform Administrators.");
  }
  if (target.role !== "platformAdmin") {
    throw denied("Only Platform Administrator accounts can be deleted here.");
  }
  if (target.uid !== undefined && target.uid === actor.uid) {
    throw denied("You cannot delete your own account.");
  }
}

/**
 * Organization Administrators are removed by platform staff or another
 * administrator in the same organization. Customer roles and platform accounts
 * are removed through their own flows.
 */
export function assertCanDeleteOrganizationAdmin(actor: Actor, target: Target): void {
  if (target.role !== "orgAdmin") {
    throw denied("Only Organization Administrator accounts can be deleted here.");
  }
  const isSameOrganizationAdmin =
    actor.role === "orgAdmin" && sameOrg(actor, target);
  if (!isPlatformRole(actor.role) && !isSameOrganizationAdmin) {
    throw denied(
      "Only platform staff or an Organization Admin in the same organization can delete an administrator.",
    );
  }
  if (target.uid !== undefined && target.uid === actor.uid) {
    throw denied("You cannot delete your own account.");
  }
}

/**
 * An organization keeps at least one active administrator, so deleting the
 * only active administrator is refused. Suspended administrators, and active
 * ones while another active administrator remains, may be deleted.
 */
export function assertOrganizationKeepsActiveAdmin(
  target: { id: string; role: Role; status: string },
  orgMembers: readonly { id: string; role: Role; status: string }[],
): void {
  if (target.role !== "orgAdmin" || target.status !== "active") return;
  const otherActiveAdmins = orgMembers.filter(
    (m) => m.role === "orgAdmin" && m.status === "active" && m.id !== target.id,
  );
  if (otherActiveAdmins.length === 0) {
    throw invalid(
      "An organization must keep at least one active administrator. " +
        "Add or reactivate another administrator first.",
    );
  }
}

/**
 * Employees and branch managers are deleted by the people who may manage them:
 * an Organization Admin for their organization, or a Branch Manager for
 * employees in their branches. Nobody deletes their own account here.
 */
export function assertCanDeleteMember(actor: Actor, target: Target): void {
  if (target.role !== "employee" && target.role !== "branchManager") {
    throw denied("Only employee and branch manager accounts can be deleted here.");
  }
  if (target.uid !== undefined && target.uid === actor.uid) {
    throw denied("You cannot delete your own account.");
  }
  if (!canReach(actor, target)) throw denied();
}

/** May the actor manage kiosks / pairing for this branch? */
export function assertCanManageBranch(
  actor: Actor,
  branch: { id: string; organizationId: string },
): void {
  if (actor.role === "orgAdmin" && actor.organizationId === branch.organizationId) {
    return;
  }
  if (
    actor.role === "branchManager" &&
    actor.organizationId === branch.organizationId &&
    actor.branchIds.includes(branch.id)
  ) {
    return;
  }
  throw denied();
}

function sameOrg(actor: Actor, target: Target): boolean {
  return (
    actor.organizationId !== undefined &&
    actor.organizationId === target.organizationId
  );
}

function assertShape(target: Target): void {
  if (isPlatformRole(target.role)) {
    if (target.organizationId) {
      throw invalid("Platform roles do not belong to an organization.");
    }
    return;
  }
  if (!target.organizationId) {
    throw invalid("organizationId is required for customer roles.");
  }
  if (target.role !== "orgAdmin" && target.branchIds.length === 0) {
    throw invalid("At least one branch is required for this role.");
  }
}

export type { Role };
