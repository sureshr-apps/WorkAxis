import { logger } from "firebase-functions/v2";
import { createHash, randomUUID } from "node:crypto";
import { Timestamp, getFirestore } from "firebase-admin/firestore";
import { precondition } from "../errors";

/** Serializes SQL edits and projection retries for the same identities. */
export async function withIdentityLocks<T>(
  uids: string[],
  action: () => Promise<T>,
): Promise<T> {
  const firestore = getFirestore();
  const token = randomUUID();
  const refs = [...new Set(uids)]
    .sort()
    .map((uid) =>
      firestore
        .collection("identity_update_locks")
        .doc(createHash("sha256").update(uid).digest("hex")),
    );
  const held: FirebaseFirestore.DocumentReference[] = [];
  try {
    for (let i = 0; i < refs.length; i += 200) {
      const chunk = refs.slice(i, i + 200);
      await firestore.runTransaction(async (tx) => {
        const snapshots = await tx.getAll(...chunk);
        if (
          snapshots.some(
            (s) =>
              s.exists &&
              (s.get("expiresAt") as Timestamp).toMillis() > Date.now(),
          )
        ) {
          throw precondition(
            "An account is being updated. Please try again shortly.",
          );
        }
        chunk.forEach((ref) =>
          tx.set(ref, {
            token,
            expiresAt: Timestamp.fromMillis(Date.now() + 180_000),
          }),
        );
      });
      held.push(...chunk);
    }
    return await action();
  } finally {
    for (let i = 0; i < held.length; i += 200) {
      const chunk = held.slice(i, i + 200);
      try {
        await firestore.runTransaction(async (tx) => {
          const snapshots = await tx.getAll(...chunk);
          snapshots.forEach((s) => {
            if (s.get("token") === token) tx.delete(s.ref);
          });
        });
      } catch (error) {
        logger.error("Identity lease cleanup failed; lease will expire", {
          errorType: error instanceof Error ? error.name : "unknown",
        });
      }
    }
  }
}
