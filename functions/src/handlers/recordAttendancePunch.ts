import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import {
  PUNCH_KINDS,
  assertInsideGeofence,
  assertPunchAllowed,
  type BreakSpan,
  type DayState,
  type PunchKind,
} from "../attendance/punchRules";
import { callableOptions } from "../config";
import { denied, guarded, notFound, precondition } from "../errors";
import { getBranch } from "../sql/branches";
import { getMemberByAuthUid } from "../sql/members";
import { workDateStart, workDateString } from "../time/workDate";
import { asBag, reqEnum, reqNumber, reqString } from "../util/input";

type StoredBreak = { startAt: Timestamp; endAt?: Timestamp };

const toDate = (t: Timestamp | undefined): Date | undefined => t?.toDate();

function readState(data: FirebaseFirestore.DocumentData | undefined): DayState {
  const breaks: BreakSpan[] = ((data?.breaks as StoredBreak[] | undefined) ?? []).map((b) => ({
    startAt: b.startAt.toDate(),
    endAt: toDate(b.endAt),
  }));
  return {
    checkInAt: toDate(data?.checkInAt),
    checkOutAt: toDate(data?.checkOutAt),
    breaks,
  };
}

/**
 * recordAttendancePunch (callable, asia-south1) - Employees only.
 * Request:  { kind: 'checkIn'|'checkOut'|'breakStart'|'breakEnd', branchId,
 *             latitude, longitude, accuracyMeters }
 * Response: { entryId, kind, recordedAt (ISO), workDate, distanceMeters }
 * Server time and the Asia/Kolkata workDate are stamped here; the geofence is
 * evaluated against the branch coordinates/radius stored in SQL.
 */
export const recordAttendancePunch = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    if (actor.role !== "employee") throw denied();

    const bag = asBag(request.data);
    const kind: PunchKind = reqEnum(bag, "kind", PUNCH_KINDS);
    const branchId = reqString(bag, "branchId", 1, 100);
    const fix = {
      latitude: reqNumber(bag, "latitude", -90, 90),
      longitude: reqNumber(bag, "longitude", -180, 180),
    };
    const accuracy = reqNumber(bag, "accuracyMeters", 0, 100_000);

    if (!actor.branchIds.includes(branchId)) throw denied("You are not assigned to this branch.");
    const branch = await getBranch(branchId);
    if (!branch || branch.status !== "active") throw notFound("Branch not found.");
    if (branch.organizationId !== actor.organizationId) throw denied();
    const distance = assertInsideGeofence(fix, accuracy, branch);

    const member = await getMemberByAuthUid(actor.uid);
    if (!member) throw denied();

    const now = new Date();
    const workDate = workDateString(now);
    const entryId = `${actor.uid}_${workDate}`;
    const ref = getFirestore().collection("attendance_entries").doc(entryId);
    const stamp = Timestamp.fromDate(now);

    await getFirestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.data();
      if (snap.exists && data?.branchId !== branchId) {
        throw precondition("You are already checked in at a different branch today.");
      }
      const state = readState(data);
      assertPunchAllowed(kind, state);

      if (kind === "checkIn") {
        tx.set(ref, {
          id: entryId,
          organizationId: branch.organizationId,
          branchId,
          employeeId: actor.uid,
          employeeName: member.fullName,
          workDate: Timestamp.fromDate(workDateStart(workDate)),
          workDateString: workDate,
          status: "present",
          reviewStatus: "none",
          checkInAt: stamp,
          breaks: [],
          kioskEntry: false,
          source: "employee-app",
          createdAt: FieldValue.serverTimestamp(),
        });
        return;
      }
      const stored = (data?.breaks as StoredBreak[] | undefined) ?? [];
      if (kind === "checkOut") tx.update(ref, { checkOutAt: stamp });
      else if (kind === "breakStart") tx.update(ref, { breaks: [...stored, { startAt: stamp }] });
      else {
        const next = stored.map((b) => (b.endAt ? b : { ...b, endAt: stamp }));
        tx.update(ref, { breaks: next });
      }
    });

    return {
      entryId,
      kind,
      recordedAt: now.toISOString(),
      workDate,
      distanceMeters: Math.round(distance),
    };
  }),
);
