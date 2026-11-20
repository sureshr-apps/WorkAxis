import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import { isPlatformRole } from "../auth/roles";
import { callableOptions } from "../config";
import { denied, guarded, notFound } from "../errors";
import { productionOrganizationDeleteSteps } from "../organizations/deletionSteps";
import { runOrganizationDeletion } from "../organizations/deletionWorkflow";
import { getOrganization } from "../sql/branches";
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

    const { membersCleaned } = await runOrganizationDeletion(
      organizationId,
      productionOrganizationDeleteSteps,
    );
    return { organizationId, deleted: true, membersCleaned };
  }),
);
