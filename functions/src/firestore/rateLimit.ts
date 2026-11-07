import { createHash } from "node:crypto";
import { Timestamp, getFirestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { RESOLVE_MAX_ATTEMPTS, RESOLVE_WINDOW_MINUTES } from "../config";

/**
 * Fixed-window attempt counter keyed by a hash of the client IP:
 * `auth_rate_limits/{sha256(ip)}`. Server-only (default-deny in rules).
 */
export async function consumeLoginLookupAttempt(clientIp: string | undefined): Promise<void> {
  const key = createHash("sha256").update(clientIp ?? "unknown").digest("hex");
  const ref = getFirestore().collection("auth_rate_limits").doc(key);
  const windowMs = RESOLVE_WINDOW_MINUTES * 60_000;

  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const start = (snap.get("windowStart") as Timestamp | undefined)?.toMillis() ?? 0;
    if (!snap.exists || now - start >= windowMs) {
      tx.set(ref, { windowStart: Timestamp.fromMillis(now), count: 1 });
      return;
    }
    const count = (snap.get("count") as number) ?? 0;
    if (count >= RESOLVE_MAX_ATTEMPTS) {
      throw new HttpsError("resource-exhausted", "Too many attempts. Try again later.");
    }
    tx.update(ref, { count: count + 1 });
  });
}
