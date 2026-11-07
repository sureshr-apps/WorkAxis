import { logger } from "firebase-functions/v2";
import { onCall } from "firebase-functions/v2/https";
import { refreshProjection } from "../accounts/target";
import { resolveActor } from "../auth/actor";
import { isPlatformRole } from "../auth/roles";
import { callableOptions } from "../config";
import { denied, guarded, notFound } from "../errors";
import { getOrganization, setOrganizationStatusSql } from "../sql/branches";
import { listMembersOfOrganization } from "../sql/members";
import { asBag, reqEnum, reqString } from "../util/input";

const CHUNK = 20;

/**
 * setOrganizationStatus (callable, asia-south1) - platform roles only.
 * Request:  { organizationId, status: 'active' | 'suspended' }
 * Response: { organizationId, status, membersUpdated, membersFailed }
 * Organization suspension must also revoke member sign-in, so it is not done
 * through the UpdateOrganization SQL Connect mutation.
 */
export const setOrganizationStatus = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    if (!isPlatformRole(actor.role)) throw denied();
    const bag = asBag(request.data);
    const organizationId = reqString(bag, "organizationId", 1, 100);
    const status = reqEnum(bag, "status", ["active", "suspended"] as const);

    if (!(await getOrganization(organizationId))) throw notFound("Organization not found.");
    await setOrganizationStatusSql(organizationId, status);

    const members = await listMembersOfOrganization(organizationId);
    let failed = 0;
    for (let i = 0; i < members.length; i += CHUNK) {
      const results = await Promise.allSettled(
        members.slice(i, i + CHUNK).map((m) =>
          refreshProjection({ ...m, organizationStatus: status }, true),
        ),
      );
      results.forEach((r) => {
        if (r.status === "rejected") {
          failed += 1;
          logger.error("org status projection failed", r.reason);
        }
      });
    }
    return { organizationId, status, membersUpdated: members.length - failed, membersFailed: failed };
  }),
);
