import { withIdentityLocks } from "./identityLocks";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { REGION } from "../config";
import { normalizeIdentity } from "../auth/aliasKeys";
import { releaseAliases, reserveAliasesTx } from "../firestore/userStore";
import { getMemberByAuthUid } from "../sql/members";
import { refreshProjection } from "./target";

/** Durable intent is saved before cross-store writes. No credentials are stored. */
export async function queueIdentitySync(uid: string, aliasKeys: string[] = []) {
  const ref = getFirestore().collection("identity_sync_jobs").doc();
  await ref.create({
    uid,
    aliasKeys,
    createdAt: FieldValue.serverTimestamp(),
    // Avoid racing a callable that is still committing its SQL transaction.
    notBefore: Timestamp.fromMillis(Date.now() + 180_000),
    attempts: 0,
  });
  return ref;
}

/** SQL is authoritative; retries always project the latest committed record. */
export async function syncIdentity(uid: string, priorAliasKeys: string[] = []) {
  return withIdentityLocks([uid], () =>
    syncIdentityWithinLock(uid, priorAliasKeys),
  );
}

/** Caller already holds the identity lease. */
export async function syncIdentityWithinLock(
  uid: string,
  priorAliasKeys: string[] = [],
) {
  const member = await getMemberByAuthUid(uid);
  if (!member) throw new Error("Identity sync target is missing.");
  const identity = normalizeIdentity({
    username: member.username,
    email: member.email.endsWith(".invalid") ? undefined : member.email,
    phone: member.phone,
  });
  await getAuth().updateUser(uid, {
    email: identity.loginEmail,
    displayName: member.fullName,
  });
  await reserveAliasesTx(
    { keys: identity.aliasKeys, loginEmail: identity.loginEmail },
    uid,
  );
  await releaseAliases(
    priorAliasKeys.filter((key) => !identity.aliasKeys.includes(key)),
    uid,
  );
  await refreshProjection(member, true);
}

export const reconcileIdentitySync = onSchedule(
  { schedule: "every 1 minutes", region: REGION },
  async () => {
    const jobs = await getFirestore()
      .collection("identity_sync_jobs")
      .where("notBefore", "<=", Timestamp.now())
      .limit(50)
      .get();
    for (const job of jobs.docs) {
      const data = job.data();
      try {
        await syncIdentity(
          data.uid as string,
          (data.aliasKeys ?? []) as string[],
        );
        await job.ref.delete();
      } catch (error) {
        logger.error("Identity projection retry failed", {
          jobId: job.id,
          errorType: error instanceof Error ? error.name : "unknown",
        });
        await job.ref.update({
          attempts: FieldValue.increment(1),
          notBefore: Timestamp.fromMillis(Date.now() + 300_000),
        });
      }
    }
  },
);
