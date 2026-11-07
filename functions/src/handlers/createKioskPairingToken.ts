import { Timestamp, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import { assertCanManageBranch } from "../auth/authorization";
import { KIOSK_TOKEN_TTL_MINUTES, callableOptions } from "../config";
import { guarded, notFound, precondition } from "../errors";
import { getBranch } from "../sql/branches";
import { newKioskToken } from "../util/kioskToken";
import { asBag, reqString } from "../util/input";

/**
 * createKioskPairingToken (callable, asia-south1)
 * Request:  { branchId }
 * Response: { token, expiresAt (ISO), branchId }
 * Callable by an Org Admin of the branch's org or a Branch Manager of the
 * branch. Only a SHA-256 hash is stored: kiosk_pairing_tokens/{hash}.
 */
export const createKioskPairingToken = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const bag = asBag(request.data);
    const branchId = reqString(bag, "branchId", 1, 100);

    const branch = await getBranch(branchId);
    if (!branch) throw notFound("Branch not found.");
    assertCanManageBranch(actor, branch);
    if (branch.status !== "active") throw precondition("Branch is not active.");

    const { token, hash } = newKioskToken();
    const expiresAt = new Date(Date.now() + KIOSK_TOKEN_TTL_MINUTES * 60_000);
    await getFirestore().collection("kiosk_pairing_tokens").doc(hash).create({
      organizationId: branch.organizationId,
      branchId,
      createdBy: actor.uid,
      createdAt: Timestamp.now(),
      expiresAt: Timestamp.fromDate(expiresAt),
      used: false,
    });
    return { token, expiresAt: expiresAt.toISOString(), branchId };
  }),
);
