import { randomUUID } from "node:crypto";
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type Firestore,
} from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { PROVISION_LOCK_STALE_SECONDS } from "../config";
import { organizationDeletionMarkerRef } from "../organizations/organizationLifecycle";

/**
 * Idempotency ledger for provisionUser: `provision_requests/{callerUid}_{requestId}`.
 * Server-only (default-deny in firestore.rules).
 */
export interface ProvisionResult {
  uid: string;
  memberId: string;
  username: string;
  loginEmail: string;
  /** Assigned or supplied employee ID (customer roles only). */
  employeeCode?: string;
}

export type LedgerClaim =
  | { kind: "done"; result: ProvisionResult }
  | { kind: "run"; uid: string; ref: FirebaseFirestore.DocumentReference };

export async function claimRequest(
  callerUid: string,
  requestId: string,
  organizationId?: string,
  db: Firestore = getFirestore(),
): Promise<LedgerClaim> {
  const ref = db.collection("provision_requests").doc(`${callerUid}_${requestId}`);
  return db.runTransaction(async (tx): Promise<LedgerClaim> => {
    if (organizationId) {
      const deletionMarker = await tx.get(
        organizationDeletionMarkerRef(organizationId, db),
      );
      if (deletionMarker.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Organization is being deleted.",
        );
      }
    }
    const snap = await tx.get(ref);
    const metadata = {
      callerUid,
      ...(organizationId ? { organizationId } : {}),
    };
    if (snap.exists) {
      const d = snap.data() ?? {};
      if (d.organizationId !== undefined && d.organizationId !== organizationId) {
        throw new HttpsError(
          "failed-precondition",
          "This request id was already used for another organization.",
        );
      }
      if (d.status === "done") {
        // Backfill metadata on older idempotency records when they are retried.
        tx.update(ref, metadata);
        return { kind: "done", result: d.result as ProvisionResult };
      }
      const lockedAt = (d.lockedAt as Timestamp | undefined)?.toMillis() ?? 0;
      const fresh = Date.now() - lockedAt < PROVISION_LOCK_STALE_SECONDS * 1000;
      if (d.status === "pending" && fresh) {
        throw new HttpsError("aborted", "This request is already being processed. Retry shortly.");
      }
      tx.update(ref, {
        ...metadata,
        status: "pending",
        lockedAt: FieldValue.serverTimestamp(),
      });
      return { kind: "run", uid: d.uid as string, ref };
    }
    // Pre-generate the uid so a retry after a partial failure reuses it.
    const uid = randomUUID().replace(/-/g, "").slice(0, 28);
    tx.create(ref, {
      ...metadata,
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
