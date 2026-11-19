import { getFirestore } from "firebase-admin/firestore";
import { getDb } from "../db";

/** Shown when an account has history; deleting it would orphan or lose that history. */
export const MEMBER_HAS_HISTORY_MESSAGE =
  "This account has attendance, return or leave records, so it cannot be deleted. Suspend it instead.";

/** Whether anything an account has done still exists. */
export interface MemberHistory {
  returnCount: number;
  hasAttendance: boolean;
  leaveRequestCount?: number;
}

/** Why the account cannot be deleted, or null when no history refers to it. Pure. */
export function memberDeletionBlocker(history: MemberHistory): string | null {
  return history.returnCount > 0 ||
    (history.leaveRequestCount ?? 0) > 0 ||
    history.hasAttendance
    ? MEMBER_HAS_HISTORY_MESSAGE
    : null;
}

/** Reads the history that refers to an account: returns in SQL, attendance in Firestore. */
export async function loadMemberHistory(authUid: string): Promise<MemberHistory> {
  const db = await getDb();
  const [returns] = await db.query<{ n: number }>(
    `SELECT count(*)::int AS n FROM return_record WHERE employee_uid = $1`,
    [authUid],
  );
  const [leaves] = await db.query<{ n: number }>(
    `SELECT count(*)::int AS n FROM leave_request WHERE applicant_uid = $1`,
    [authUid],
  );
  const firestore = getFirestore();
  const entries = await firestore
    .collection("attendance_entries")
    .where("employeeId", "==", authUid)
    .limit(1)
    .get();
  const batches = await firestore
    .collection("group_attendance_batches")
    .where("employeeIds", "array-contains", authUid)
    .limit(1)
    .get();
  return {
    returnCount: returns?.n ?? 0,
    leaveRequestCount: leaves?.n ?? 0,
    hasAttendance: !entries.empty || !batches.empty,
  };
}
