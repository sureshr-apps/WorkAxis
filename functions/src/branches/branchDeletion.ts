import { getFirestore } from "firebase-admin/firestore";
import { getDb } from "../db";

/** Shown when a branch still has people or history; deleting it would orphan or lose them. */
export const BRANCH_HAS_HISTORY_MESSAGE =
  "This branch has employees, returns, leave or attendance records, so it cannot be deleted. Suspend it instead.";

/** Firestore collections that record attendance for a branch. */
const ATTENDANCE_COLLECTIONS = ["attendance_entries", "group_attendance_batches"] as const;

/** Whether attendance records exist for the branch in Firestore. */
export async function hasAttendanceHistory(branchId: string): Promise<boolean> {
  const db = getFirestore();
  for (const name of ATTENDANCE_COLLECTIONS) {
    const found = await db.collection(name).where("branchId", "==", branchId).limit(1).get();
    if (!found.empty) return true;
  }
  return false;
}

/**
 * Why the branch cannot be deleted, or null when nothing refers to it. Employee
 * assignments (including branch managers), returns and leave live in SQL;
 * attendance lives in Firestore and is checked through [attendanceHistory].
 */
export async function branchDeletionBlocker(
  branchId: string,
  attendanceHistory: (branchId: string) => Promise<boolean> = hasAttendanceHistory,
): Promise<string | null> {
  const db = await getDb();
  const [assignments] = await db.query<{ n: number }>(
    `SELECT count(*)::int AS n FROM user_branch_assignment WHERE branch_id = $1`,
    [branchId],
  );
  const [returns] = await db.query<{ n: number }>(
    `SELECT count(*)::int AS n FROM return_record WHERE branch_id = $1`,
    [branchId],
  );
  const [leaves] = await db.query<{ n: number }>(
    `SELECT count(*)::int AS n FROM leave_request WHERE branch_id = $1`,
    [branchId],
  );
  if (
    (assignments?.n ?? 0) > 0 ||
    (returns?.n ?? 0) > 0 ||
    (leaves?.n ?? 0) > 0
  ) return BRANCH_HAS_HISTORY_MESSAGE;
  if (await attendanceHistory(branchId)) return BRANCH_HAS_HISTORY_MESSAGE;
  return null;
}

/** Removes the branch row. Callers check [branchDeletionBlocker] first. */
export async function deleteBranchRow(branchId: string, organizationId: string): Promise<void> {
  const db = await getDb();
  await db.query(`DELETE FROM branch WHERE id = $1 AND organization_id = $2`, [
    branchId,
    organizationId,
  ]);
}
