import { onCall } from "firebase-functions/v2/https";
import { refreshProjection, loadTarget } from "../accounts/target";
import { resolveActor } from "../auth/actor";
import { assertCanManage } from "../auth/authorization";
import { callableOptions } from "../config";
import { guarded } from "../errors";
import { getMemberByAuthUid, updateMember } from "../sql/members";
import { asBag, reqEnum, reqString } from "../util/input";

/**
 * setUserStatus (callable, asia-south1)
 * Request:  { targetUid, status: 'active' | 'suspended' }
 * Response: { uid, status }
 * Suspension disables the Auth user, revokes refresh tokens and sets the
 * claim status so SQL Connect and Firestore deny the user immediately.
 */
export const setUserStatus = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const bag = asBag(request.data);
    const targetUid = reqString(bag, "targetUid", 1, 128);
    const status = reqEnum(bag, "status", ["active", "suspended"] as const);

    const { member, target } = await loadTarget(targetUid);
    assertCanManage(actor, target, "setStatus");

    await updateMember(member.id, { status });
    const updated = (await getMemberByAuthUid(targetUid)) ?? { ...member, status };
    await refreshProjection(updated, true);
    return { uid: targetUid, status };
  }),
);
