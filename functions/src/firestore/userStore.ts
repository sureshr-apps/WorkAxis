import { FieldValue, getFirestore, type Transaction } from "firebase-admin/firestore";
import { conflict } from "../errors";
import type { MemberRecord } from "../sql/members";
import { effectiveStatus } from "../auth/actor";

/**
 * Firestore projections of SQL identity. Both collections are written ONLY
 * here (clients are denied by firestore.rules).
 *   user_aliases/{normalizedIdentifier} = { userId, email }
 *   users/{uid} = profile projection (read-only for clients)
 */
export interface AliasSet {
  /** normalized key -> login email */
  keys: string[];
  loginEmail: string;
}

export const aliasCol = () => getFirestore().collection("user_aliases");
export const usersCol = () => getFirestore().collection("users");

/** Reserves alias keys for `uid` (create-only; idempotent for the same uid). */
export async function reserveAliases(
  tx: Transaction,
  set: AliasSet,
  uid: string,
): Promise<void> {
  const refs = set.keys.map((k) => aliasCol().doc(k));
  const snaps = await Promise.all(refs.map((r) => tx.get(r)));
  snaps.forEach((s) => {
    if (s.exists && s.get("userId") !== uid) {
      throw conflict("That username, email or phone number is already in use.");
    }
  });
  refs.forEach((ref, i) => {
    if (!snaps[i].exists) tx.create(ref, { userId: uid, email: set.loginEmail });
    else tx.update(ref, { email: set.loginEmail });
  });
}

export async function reserveAliasesTx(set: AliasSet, uid: string): Promise<void> {
  await getFirestore().runTransaction((tx) => reserveAliases(tx, set, uid));
}

/** Deletes alias docs that belong to `uid` (never another user's). */
export async function releaseAliases(keys: string[], uid: string): Promise<void> {
  await getFirestore().runTransaction(async (tx) => {
    const refs = keys.map((k) => aliasCol().doc(k));
    const snaps = await Promise.all(refs.map((r) => tx.get(r)));
    snaps.forEach((s, i) => {
      if (s.exists && s.get("userId") === uid) tx.delete(refs[i]);
    });
  });
}

/** Writes/refreshes the read-only profile projection for a member. */
export async function writeProfile(member: MemberRecord): Promise<void> {
  const doc: Record<string, unknown> = {
    name: member.fullName,
    role: member.role,
    status: effectiveStatus(member),
    username: member.username,
    email: member.email,
    branchIds: [...member.branchIds].sort(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (member.phone) doc.phone = member.phone;
  if (member.organizationId) doc.organizationId = member.organizationId;
  await usersCol().doc(member.authUid).set(doc);
}

export async function deleteProfile(uid: string): Promise<void> {
  await usersCol().doc(uid).delete();
}
