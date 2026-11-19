import { onCall } from "firebase-functions/v2/https";
import { loadTarget } from "../accounts/target";
import { resolveActor } from "../auth/actor";
import { assertCanDeleteMember } from "../auth/authorization";
import { callableOptions } from "../config";
import { guarded, invalid } from "../errors";
import { loadMemberHistory, memberDeletionBlocker } from "../employees/memberDeletion";
import { deleteMemberIdentity } from "../organizations/deletionSteps";
import { deleteMemberByAuthUid } from "../sql/members";
import { asBag, reqString } from "../util/input";

/**
 * deleteOrganizationMember (callable, asia-south1)
 * Request:  { targetUid }
 * Response: { uid, deleted }
 * Removes an employee or branch manager. Refused while the account has return
 * or leave records, which must be kept; suspend those accounts instead.
 * The login identity and profile go first and the SQL member last, so a
 * failure leaves the account in place and the same call can be retried.
 */
export const deleteOrganizationMember = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const bag = asBag(request.data);
    const targetUid = reqString(bag, "targetUid", 1, 128);

    const { member, target } = await loadTarget(targetUid);
    assertCanDeleteMember(actor, target);
    const blocker = memberDeletionBlocker(await loadMemberHistory(targetUid));
    if (blocker) throw invalid(blocker);

    await deleteMemberIdentity(member);
    await deleteMemberByAuthUid(targetUid);
    return { uid: targetUid, deleted: true };
  }),
);
