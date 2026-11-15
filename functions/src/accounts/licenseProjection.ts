import { logger } from "firebase-functions/v2";
import { asBag } from "../util/input";
import { listMembersOfOrganization } from "../sql/members";
import { refreshProjection } from "./target";

const CHUNK = 20;

/** Operations that can change whether an organization's license is usable. */
const LICENSE_CHANGE_OPS: ReadonlySet<string> = new Set([
  "AssignOrganizationLicense",
  "ChangeOrganizationLicensePlan",
  "RenewOrganizationLicense",
]);

/**
 * Re-projects every member of the organization named in a successful license
 * change, so claims, the Auth disabled flag and users/{uid} agree with
 * effectiveStatus. Other operations are ignored.
 */
export async function reprojectAfterLicenseChange(request: unknown): Promise<void> {
  const bag = asBag(request);
  if (typeof bag.op !== "string" || !LICENSE_CHANGE_OPS.has(bag.op)) return;
  const { organizationId } = asBag(bag.vars);
  if (typeof organizationId !== "string") return;
  try {
    await reprojectOrganizationMembers(organizationId);
  } catch (error) {
    logger.error("license projection failed", error);
  }
}

/**
 * Runs after the SQL commit, so a failed member is logged rather than thrown
 * (same best-effort pattern as setOrganizationStatus).
 */
async function reprojectOrganizationMembers(organizationId: string): Promise<void> {
  const members = await listMembersOfOrganization(organizationId);
  for (let i = 0; i < members.length; i += CHUNK) {
    const results = await Promise.allSettled(
      members.slice(i, i + CHUNK).map((member) => refreshProjection(member)),
    );
    results.forEach((result) => {
      if (result.status === "rejected") {
        logger.error("license projection failed", result.reason);
      }
    });
  }
}
