import { precondition } from "../errors";
import { getBranches, getOrganization } from "../sql/branches";

/**
 * Confirms the organization exists and is active and that every branch
 * belongs to it and is active. Prevents cross-tenant branch assignment even
 * when the caller's own scope check passes.
 */
export async function assertOrgAndBranchesValid(
  organizationId: string,
  branchIds: string[],
): Promise<void> {
  const org = await getOrganization(organizationId);
  if (!org) throw precondition("Organization not found.");
  if (org.status !== "active") throw precondition("Organization is not active.");
  if (branchIds.length === 0) return;
  const found = await getBranches(branchIds);
  const ok =
    found.length === branchIds.length &&
    found.every((b) => b.organizationId === organizationId && b.status === "active");
  if (!ok) throw precondition("One or more branches are invalid for this organization.");
}
