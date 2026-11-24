import { FieldValue, Timestamp, type Firestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { ENTRIES, SESSION_STATE } from "./attendanceStore";

const BATCH = 200;

export interface SweepResult {
  flaggedOverdue: number;
  closedMissing: number;
}

/**
 * Advances open sessions past their deadlines:
 * - overdue: the shift ended and the overtime allowance passed without a
 *   check-out. The entry is flagged for the manager; the session stays open
 *   because the employee may still be working.
 * - expired: the maximum session length passed. The session is closed
 *   administratively and marked as a missing check-out for correction. No
 *   check-out time is written; the closure is recorded separately.
 * Each change runs in a transaction that re-checks the session, so a
 * check-out racing the sweep wins.
 */
export async function sweepAttendanceSessions(firestore: Firestore, now: Date): Promise<SweepResult> {
  const states = firestore.collection(SESSION_STATE);
  const nowStamp = Timestamp.fromDate(now);
  let closedMissing = 0;
  let flaggedOverdue = 0;

  const expired = await states.where("sessionExpiresAt", "<=", nowStamp).limit(BATCH).get();
  for (const state of expired.docs) {
    try {
      const closed = await firestore.runTransaction(async (tx) => {
        const fresh = await tx.get(state.ref);
        const entryId = fresh.get("activeEntryId");
        const expiresAt = fresh.get("sessionExpiresAt");
        if (!fresh.exists || typeof entryId !== "string" ||
            !(expiresAt instanceof Timestamp) || expiresAt.toMillis() > now.getTime()) {
          return false;
        }
        const entryRef = firestore.collection(ENTRIES).doc(entryId);
        const entry = await tx.get(entryRef);
        if (entry.exists && !entry.get("checkOutAt")) {
          tx.update(entryRef, {
            open: false,
            status: "incomplete",
            checkoutStatus: "missing",
            reviewStatus: "needsReview",
            sessionClosure: {
              closedAt: FieldValue.serverTimestamp(),
              closedBy: "system",
              reason: "maxSessionExceeded",
            },
          });
        }
        tx.delete(state.ref);
        return true;
      });
      if (closed) closedMissing++;
    } catch (error) {
      logger.error("Attendance session expiry failed", { stateId: state.id, error });
    }
  }

  const overdue = await states
    .where("overdueFlagged", "==", false)
    .where("checkoutOverdueAt", "<=", nowStamp)
    .limit(BATCH)
    .get();
  for (const state of overdue.docs) {
    try {
      const flagged = await firestore.runTransaction(async (tx) => {
        const fresh = await tx.get(state.ref);
        const entryId = fresh.get("activeEntryId");
        if (!fresh.exists || typeof entryId !== "string" || fresh.get("overdueFlagged") === true) {
          return false;
        }
        const entryRef = firestore.collection(ENTRIES).doc(entryId);
        const entry = await tx.get(entryRef);
        if (entry.exists && !entry.get("checkOutAt")) {
          tx.update(entryRef, { checkoutStatus: "overdue", reviewStatus: "needsReview" });
        }
        tx.update(state.ref, { overdueFlagged: true });
        return true;
      });
      if (flagged) flaggedOverdue++;
    } catch (error) {
      logger.error("Attendance overdue flag failed", { stateId: state.id, error });
    }
  }
  return { flaggedOverdue, closedMissing };
}
