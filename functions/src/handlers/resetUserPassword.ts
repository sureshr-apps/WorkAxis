import { getAuth } from "firebase-admin/auth";
import { onCall } from "firebase-functions/v2/https";
import { loadTarget } from "../accounts/target";
import { resolveActor } from "../auth/actor";
import { assertCanManage } from "../auth/authorization";
import { MIN_PASSWORD_LENGTH, callableOptions } from "../config";
import { guarded } from "../errors";
import { asBag, reqString } from "../util/input";

/**
 * resetUserPassword (callable, asia-south1)
 * Request:  { targetUid, newPassword }
 * Response: { uid }
 * The password is set as-is (no forced change) and sessions are revoked.
 */
export const resetUserPassword = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const bag = asBag(request.data);
    const targetUid = reqString(bag, "targetUid", 1, 128);
    const newPassword = reqString(bag, "newPassword", MIN_PASSWORD_LENGTH, 128);

    const { target } = await loadTarget(targetUid);
    assertCanManage(actor, target, "resetPassword");

    await getAuth().updateUser(targetUid, { password: newPassword });
    await getAuth().revokeRefreshTokens(targetUid);
    return { uid: targetUid };
  }),
);
