import { FieldValue, getFirestore, type Transaction } from "firebase-admin/firestore";
import { conflict } from "../errors";
import type { MemberRecord } from "../sql/members";
import { effectiveStatus } from "../auth/actor";
import type { EmployeeProfileExtras } from "../util/employeeProfile";

/**
 * Firestore projections of SQL identity. Both collections are written ONLY
 * here (clients are denied by firestore.rules).
 *   user_aliases/{normalizedIdentifier} = { userId, email }
 *   users/{uid} = profile projection (read-only for clients)
 *   employee_private/{uid} = { organizationId, salary?, aadhaarNumber?,
 *     aadhaarPhotoUrl?, updatedAt }  sensitive HR data, never in users/{uid}
 */
export interface AliasSet {
  /** normalized key -> login email */
  keys: string[];
  loginEmail: string;
}

export const aliasCol = () => getFirestore().collection("user_aliases");
export const usersCol = () => getFirestore().collection("users");
export const employeePrivateCol = () => getFirestore().collection("employee_private");

/** Profile keys that must never live on the manager-readable users/{uid} doc. */
const PRIVATE_KEYS = ["aadhaarNumber", "aadhaarPhotoUrl"] as const;

/**
 * Firestore patch for the sensitive HR fields: a value sets, `null` deletes the
 * field, `undefined` leaves it untouched. Empty when nothing is given.
 */
export function buildPrivatePatch(extra?: Pick<EmployeeProfileExtra, (typeof PRIVATE_KEYS)[number]>): Record<string, unknown> {
  const patch: Record<string, unknown> = {};
  if (!extra) return patch;
  for (const key of PRIVATE_KEYS) {
    const v = extra[key];
    if (v === null) patch[key] = FieldValue.delete();
    else if (v !== undefined) patch[key] = v;
  }
  return patch;
}

const PROFILE_KEYS = [
  "dateOfBirth",
  "gender",
  "address",
  "profilePhotoUrl",
  "designation",
  "joiningDate",
  "relievingDate",
  "assetDetails",
] as const;

/**
 * Firestore patch for the manager-readable users/{uid} profile fields, with the
 * same set / delete(null) / untouched(undefined) semantics as [buildPrivatePatch].
 */
export function buildProfilePatch(extra?: EmployeeProfileExtra): Record<string, unknown> {
  const patch: Record<string, unknown> = {};
  if (!extra) return patch;
  for (const key of PROFILE_KEYS) {
    const v = extra[key];
    if (v === null) patch[key] = FieldValue.delete();
    else if (v !== undefined) patch[key] = v;
  }
  return patch;
}

/** Writes sensitive HR fields to employee_private/{uid}; no-op when none are given. */
export async function writeEmployeePrivate(
  uid: string,
  organizationId: string | undefined,
  extra?: Pick<EmployeeProfileExtra, (typeof PRIVATE_KEYS)[number]>,
): Promise<void> {
  if (!organizationId) return;
  const doc = buildPrivatePatch(extra);
  if (Object.keys(doc).length === 0) return;
  await employeePrivateCol()
    .doc(uid)
    .set({ ...doc, organizationId, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
}

/** FieldValue.delete() for each private key, to scrub legacy users/{uid} docs. */
export function privateKeyScrub(): Record<string, FieldValue> {
  return Object.fromEntries(PRIVATE_KEYS.map((k) => [k, FieldValue.delete()]));
}

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

/** Profile extras; `null` clears a stored field (see EmployeeProfileExtras). */
export type EmployeeProfileExtra = EmployeeProfileExtras;

/** Writes/refreshes the read-only profile projection for a member. */
export async function writeProfile(
  member: MemberRecord,
  extra?: EmployeeProfileExtra,
): Promise<void> {
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
  // SQL is authoritative for the employee ID.
  if (member.employeeCode !== undefined) doc.employeeCode = member.employeeCode;
  Object.assign(doc, buildProfilePatch(extra));
  // Move sensitive HR data out of the manager-readable doc; also cleans legacy docs.
  await writeEmployeePrivate(member.authUid, member.organizationId, extra);
  await usersCol()
    .doc(member.authUid)
    .set({ ...doc, ...privateKeyScrub() }, { merge: true });
}

export async function deleteProfile(uid: string): Promise<void> {
  await Promise.all([usersCol().doc(uid).delete(), employeePrivateCol().doc(uid).delete()]);
}
