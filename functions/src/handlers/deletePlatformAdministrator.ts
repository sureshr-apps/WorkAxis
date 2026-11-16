import { onCall } from "firebase-functions/v2/https";
import { loadTarget } from "../accounts/target";
import { resolveActor } from "../auth/actor";
import { assertCanDeletePlatformAdministrator } from "../auth/authorization";
import { callableOptions } from "../config";
import { guarded } from "../errors";
import { deleteMemberIdentity } from "../organizations/deletionSteps";
import { deleteMemberByAuthUid } from "../sql/members";
import { asBag, reqString } from "../util/input";

/**
 * deletePlatformAdministrator (callable, asia-south1) - Platform Owner only.
 * Request:  { targetUid }
 * Response: { uid, deleted }
 * Removes the login identity and profile first and the SQL member last, so a
 * failure leaves the administrator in place and the same call can be retried.
 */
export const deletePlatformAdministrator = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const bag = asBag(request.data);
    const targetUid = reqString(bag, "targetUid", 1, 128);

    const { member, target } = await loadTarget(targetUid);
    assertCanDeletePlatformAdministrator(actor, target);

    await deleteMemberIdentity(member);
    await deleteMemberByAuthUid(targetUid);
    return { uid: targetUid, deleted: true };
  }),
);
