import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import { branchDeletionBlocker, deleteBranchRow } from "../branches/branchDeletion";
import { callableOptions } from "../config";
import { denied, guarded, notFound, precondition } from "../errors";
import { getBranch } from "../sql/branches";
import { asBag, reqString } from "../util/input";

/**
 * Deletes a branch that has no employees, returns or attendance. Only the
 * organization admin of the branch's organization may delete it.
 */
export const deleteBranch = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    if (actor.role !== "orgAdmin" || !actor.organizationId) throw denied();
    const bag = asBag(request.data);
    const id = reqString(bag, "id", 1, 100);

    const branch = await getBranch(id);
    if (!branch || branch.organizationId !== actor.organizationId) {
      throw notFound("Branch not found.");
    }
    const blocker = await branchDeletionBlocker(id);
    if (blocker) throw precondition(blocker);
    await deleteBranchRow(id, actor.organizationId);
    return { id, deleted: true };
  }),
);
