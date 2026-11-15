import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import { isPlatformRole } from "../auth/roles";
import { callableOptions } from "../config";
import { denied, guarded, notFound } from "../errors";
import { productionOrganizationDeleteSteps } from "../organizations/deletionSteps";
import { runOrganizationDeletion } from "../organizations/deletionWorkflow";
import { getOrganization } from "../sql/branches";
import { listMembersOfOrganization } from "../sql/members";
import { asBag, reqString } from "../util/input";

/**
 * Idempotent, retryable deletion. SQL is removed last, so any earlier failure
 * leaves the organization and its members intact and the call can be retried.
 */
export const deleteOrganization = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    if (!isPlatformRole(actor.role)) throw denied();
    const bag = asBag(request.data);
    const organizationId = reqString(bag, "organizationId", 1, 100);

    if (!(await getOrganization(organizationId))) {
      throw notFound("Organization not found.");
    }

    // Read members before any step: they are needed for Auth/alias cleanup.
    const members = await listMembersOfOrganization(organizationId);
    const { membersCleaned } = await runOrganizationDeletion(
      organizationId,
      members,
      productionOrganizationDeleteSteps,
    );
    return { organizationId, deleted: true, membersCleaned };
  }),
);
