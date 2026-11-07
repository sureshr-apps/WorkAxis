import { randomUUID } from "node:crypto";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { PROVISION_LOCK_STALE_SECONDS } from "../config";

/**
 * Idempotency ledger for provisionUser: `provision_requests/{callerUid}_{requestId}`.
 * Server-only (default-deny in firestore.rules).
 */
export interface ProvisionResult {
  uid: string;
  memberId: string;
  username: string;
  loginEmail: string;
}

export type LedgerClaim =
  | { kind: "done"; result: ProvisionResult }
  | { kind: "run"; uid: string; ref: FirebaseFirestore.DocumentReference };

export async function claimRequest(callerUid: string, requestId: string): Promise<LedgerClaim> {
  const ref = getFirestore().collection("provision_requests").doc(`${callerUid}_${requestId}`);
  return getFirestore().runTransaction(async (tx): Promise<LedgerClaim> => {
    const snap = await tx.get(ref);
    if (snap.exists) {
      const d = snap.data() ?? {};
      if (d.status === "done") return { kind: "done", result: d.result as ProvisionResult };
      const lockedAt = (d.lockedAt as Timestamp | undefined)?.toMillis() ?? 0;
      const fresh = Date.now() - lockedAt < PROVISION_LOCK_STALE_SECONDS * 1000;
      if (d.status === "pending" && fresh) {
        throw new HttpsError("aborted", "This request is already being processed. Retry shortly.");
      }
      tx.update(ref, { status: "pending", lockedAt: FieldValue.serverTimestamp() });
      return { kind: "run", uid: d.uid as string, ref };
    }
    // Pre-generate the uid so a retry after a partial failure reuses it.
    const uid = randomUUID().replace(/-/g, "").slice(0, 28);
    tx.create(ref, {
      status: "pending",
      uid,
      lockedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    });
    return { kind: "run", uid, ref };
  });
}

export const markDone = (ref: FirebaseFirestore.DocumentReference, result: ProvisionResult) =>
  ref.update({ status: "done", result, finishedAt: FieldValue.serverTimestamp() });

export const markFailed = (ref: FirebaseFirestore.DocumentReference, reason: string) =>
  ref.update({ status: "failed", reason, finishedAt: FieldValue.serverTimestamp() });
