import { FieldValue, Timestamp, getFirestore, type DocumentData } from "firebase-admin/firestore";
import type { Actor } from "../../auth/roles";
import {
  CORRECTIONS,
  ENTRIES,
  entryBreaks,
  recomputeDayOvertime,
} from "../../attendance/attendanceStore";
import { approvedOvertimeHours, validateRequestedCheckOut } from "../../attendance/corrections";
import { denied, invalid, notFound, precondition } from "../../errors";
import { optString, reqEnum, reqString } from "../../util/input";
import { requireBranchManagerContext, requireRole } from "../authz";
import type { OperationRegistry } from "../operation";
import { selectOne } from "../sql";
import { optNum, reqId } from "../vars";

const DECISIONS = ["approve", "reject"] as const;
const NOT_FOUND = "Attendance record not found.";

/**
 * Attendance exceptions that need a person: an employee's request to correct
 * a missing or late check-out, and the manager's approval of overtime.
 * Attendance lives in Firestore; each decision updates the attendance entry
 * and its request in one Firestore transaction.
 */
export const attendanceReviewOps: OperationRegistry = {
  /** Employee (or Branch Manager for their own attendance) asks to correct a check-out. */
  RequestCheckoutCorrection: async ({ actor }, vars) => {
    requireRole(actor, ["employee", "branchManager"]);
    const entryId = reqId(vars, "entryId");
    const requested = reqInstant(vars, "checkOutAt");
    const reason = reqString(vars, "reason", 1, 500).trim();
    if (!reason) throw invalid("Explain why the check-out needs correcting.");
    const firestore = getFirestore();
    const entryRef = firestore.collection(ENTRIES).doc(entryId);
    const correctionRef = firestore.collection(CORRECTIONS).doc();
    await firestore.runTransaction(async (tx) => {
      const entry = await tx.get(entryRef);
      const data = entry.data();
      if (!entry.exists || !data || data.employeeId !== actor.uid ||
          data.organizationId !== actor.organizationId) {
        throw notFound(NOT_FOUND);
      }
      validateRequestedCheckOut({
        checkInAt: instant(data.checkInAt),
        checkOutAt: instant(data.checkOutAt),
        breaks: entryBreaks(data),
        checkoutStatus: typeof data.checkoutStatus === "string" ? data.checkoutStatus : "none",
        correctionStatus: typeof data.correctionStatus === "string" ? data.correctionStatus : null,
      }, requested, new Date());
      tx.create(correctionRef, {
        id: correctionRef.id,
        entryId,
        organizationId: data.organizationId,
        branchId: data.branchId,
        employeeId: actor.uid,
        employeeName: data.employeeName ?? null,
        workDateString: data.workDateString,
        checkInAt: data.checkInAt,
        recordedCheckOutAt: data.checkOutAt ?? null,
        requestedCheckOutAt: Timestamp.fromDate(requested),
        reason,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(entryRef, { correctionStatus: "pending", correctionId: correctionRef.id });
    });
    return { correction: { id: correctionRef.id, status: "pending" } };
  },

  /** Org Admin, or Branch Manager of the active branch, approves or rejects a correction. */
  ReviewCheckoutCorrection: async ({ db, actor }, vars) => {
    requireRole(actor, ["orgAdmin", "branchManager"]);
    const id = reqId(vars, "id");
    const decision = reqEnum(vars, "decision", DECISIONS);
    const note = optString(vars, "note", 1, 500)?.trim() || null;
    const firestore = getFirestore();
    const correctionRef = firestore.collection(CORRECTIONS).doc(id);
    const reviewer = await reviewerName(db, actor);
    let result: DocumentData = {};
    await firestore.runTransaction(async (tx) => {
      const correction = await tx.get(correctionRef);
      const data = correction.data();
      if (!correction.exists || !data) throw notFound("Correction request not found.");
      assertReviewScope(actor, vars, data);
      if (data.status !== "pending") throw precondition("This correction has already been reviewed.");
      const entryRef = firestore.collection(ENTRIES).doc(data.entryId as string);
      const entry = await tx.get(entryRef);
      if (!entry.exists) throw notFound(NOT_FOUND);
      const review = {
        reviewedById: actor.uid,
        reviewedBy: reviewer,
        reviewedAt: FieldValue.serverTimestamp(),
        reviewNote: note,
      };
      if (decision === "approve") {
        const checkOutAt = (data.requestedCheckOutAt as Timestamp).toDate();
        // The corrected time is stored as a correction, beside the original
        // record: the administrative closure (if any) stays on the entry.
        await recomputeDayOvertime(
          firestore, tx, data.employeeId, data.organizationId, data.workDateString,
          {
            id: entryRef.id,
            checkOutAt,
            extra: {
              checkOutAt: data.requestedCheckOutAt,
              checkOutSource: "correction",
              recordedCheckOutAt: entry.get("checkOutAt") ?? null,
              open: false,
              status: "present",
              checkoutStatus: "corrected",
              correctionStatus: "approved",
              reviewStatus: "verified",
              ...review,
            },
          },
        );
      } else {
        tx.update(entryRef, { correctionStatus: "rejected" });
      }
      tx.update(correctionRef, { status: decision === "approve" ? "approved" : "rejected", ...review });
      result = { id, status: decision === "approve" ? "approved" : "rejected" };
    });
    return { correction: result };
  },

  /** Org Admin, or Branch Manager of the active branch, approves or rejects overtime. */
  ReviewOvertime: async ({ db, actor }, vars) => {
    requireRole(actor, ["orgAdmin", "branchManager"]);
    const entryId = reqId(vars, "entryId");
    const decision = reqEnum(vars, "decision", DECISIONS);
    const requestedHours = optNum(vars, "approvedHours", 0, 24);
    const firestore = getFirestore();
    const entryRef = firestore.collection(ENTRIES).doc(entryId);
    const reviewer = await reviewerName(db, actor);
    let result: DocumentData = {};
    await firestore.runTransaction(async (tx) => {
      const entry = await tx.get(entryRef);
      const data = entry.data();
      if (!entry.exists || !data) throw notFound(NOT_FOUND);
      assertReviewScope(actor, vars, data);
      if (!data.checkOutAt) throw precondition("Overtime can be reviewed after check-out.");
      const potential = Number(data.potentialOvertimeHours ?? 0);
      const review = {
        overtimeReviewedById: actor.uid,
        overtimeReviewedBy: reviewer,
        overtimeReviewedAt: FieldValue.serverTimestamp(),
      };
      if (decision === "approve") {
        const hours = approvedOvertimeHours(potential, requestedHours);
        tx.update(entryRef, { overtimeStatus: "approved", approvedOvertimeHours: hours, ...review });
        result = { entryId, overtimeStatus: "approved", approvedOvertimeHours: hours };
      } else {
        if (!(potential > 0)) throw precondition("This attendance has no overtime to review.");
        tx.update(entryRef, {
          overtimeStatus: "rejected",
          approvedOvertimeHours: FieldValue.delete(),
          ...review,
        });
        result = { entryId, overtimeStatus: "rejected", approvedOvertimeHours: 0 };
      }
    });
    return { overtime: result };
  },
};

/** Reviewers act within their organization (Branch Managers: active branch) and never on their own attendance. */
function assertReviewScope(actor: Actor, vars: Record<string, unknown>, data: DocumentData): void {
  if (data.organizationId !== actor.organizationId) throw notFound(NOT_FOUND);
  requireBranchManagerContext(actor, vars, data.branchId as string, NOT_FOUND);
  if (data.employeeId === actor.uid) throw denied("You cannot review your own attendance.");
}

async function reviewerName(db: Parameters<OperationRegistry[string]>[0]["db"], actor: Actor): Promise<string | null> {
  const row = await selectOne<{ fullName: string }>(
    db,
    `SELECT full_name AS "fullName" FROM organization_member WHERE auth_uid = $1 LIMIT 1`,
    [actor.uid],
  );
  return row?.fullName ?? null;
}

function reqInstant(vars: Record<string, unknown>, key: string): Date {
  const value = vars[key];
  const ms = typeof value === "string" ? Date.parse(value) : Number.NaN;
  if (Number.isNaN(ms)) throw invalid(`${key} must be an ISO-8601 timestamp.`);
  return new Date(ms);
}

function instant(value: unknown): Date | null {
  return value instanceof Timestamp ? value.toDate() : null;
}
