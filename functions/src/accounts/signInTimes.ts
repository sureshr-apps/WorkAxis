import { getAuth } from "firebase-admin/auth";

/**
 * Last sign-in time per Firebase Auth uid. Auth is the only place sign-ins are
 * recorded, so the member lists read it here. Uids Auth does not know are left
 * out, so callers show "never signed in" for them.
 */
export type SignInLookup = (uids: string[]) => Promise<Map<string, string>>;

/** Auth accepts at most 100 identifiers per getUsers call. */
const BATCH = 100;

const fromAuth: SignInLookup = async (uids) => {
  const unique = [...new Set(uids)];
  const times = new Map<string, string>();
  for (let i = 0; i < unique.length; i += BATCH) {
    const batch = unique.slice(i, i + BATCH).map((uid) => ({ uid }));
    const result = await getAuth().getUsers(batch);
    for (const user of result.users) {
      const last = user.metadata.lastSignInTime;
      if (last) times.set(user.uid, new Date(last).toISOString());
    }
  }
  return times;
};

let lookup: SignInLookup = fromAuth;

/** Last sign-in time (ISO 8601, UTC) for each of the given uids that has one. */
export function lastSignInTimes(uids: string[]): Promise<Map<string, string>> {
  return lookup(uids.filter((uid) => uid.length > 0));
}

/** Replaces the Auth lookup in tests; pass undefined to restore it. */
export function setSignInLookupForTests(next: SignInLookup | undefined): void {
  lookup = next ?? fromAuth;
}
