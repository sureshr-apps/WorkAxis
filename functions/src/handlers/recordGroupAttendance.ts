import { createHash } from "node:crypto";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import {
  assertGroupAttendee,
  assertGroupScope,
  parseGroupAttendance,
} from "../attendance/groupRules";
import { callableOptions } from "../config";
import { conflict, guarded, notFound } from "../errors";
import { getBranch } from "../sql/branches";
import { getMemberByAuthUid, type MemberRecord } from "../sql/members";
import { workDateStart } from "../time/workDate";

/** Validates authoritative SQL membership before an atomic, idempotent batch. */
export const recordGroupAttendance = onCall(callableOptions, (request) =>
  guarded(async () => {
    const actor = await resolveActor(request);
    const input = parseGroupAttendance(request.data, new Date());
    const branch = await getBranch(input.branchId);
    if (!branch) throw notFound("Branch not found.");
    assertGroupScope(actor, branch);
    const attendees: MemberRecord[] = [];
    // Bounded chunks avoid opening hundreds of simultaneous SQL requests.
    for (let i = 0; i < input.employeeIds.length; i += 20) {
      const chunk = await Promise.all(
        input.employeeIds.slice(i, i + 20).map(getMemberByAuthUid),
      );
      for (const member of chunk) {
        assertGroupAttendee(member, branch.organizationId, branch.id);
        attendees.push(member!);
      }
    }
    const firestore = getFirestore();
    const batchId = `${actor.uid}_${input.requestId}`;
    const batchRef = firestore
      .collection("group_attendance_batches")
      .doc(batchId);
    const fingerprint = createHash("sha256")
      .update(JSON.stringify(input))
      .digest("hex");
    const refs = attendees.map((m) =>
      firestore
        .collection("attendance_entries")
        .doc(`${m.authUid}_${input.workDate}`),
    );
    await firestore.runTransaction(async (tx) => {
      const existingBatch = await tx.get(batchRef);
      if (existingBatch.exists) {
        if (existingBatch.get("fingerprint") !== fingerprint)
          throw conflict(
            "This request id was already used for different attendance.",
          );
        return;
      }
      const existing = await tx.getAll(...refs);
      if (existing.some((doc) => doc.exists))
        throw conflict(
          "Some selected employees already have attendance for this day.",
        );
      attendees.forEach((member, index) =>
        tx.create(refs[index], {
          id: refs[index].id,
          organizationId: branch.organizationId,
          branchId: branch.id,
          employeeId: member.authUid,
          employeeName: member.fullName,
          workDate: Timestamp.fromDate(workDateStart(input.workDate)),
          workDateString: input.workDate,
          status: input.status,
          reviewStatus: "none",
          checkInAt: Timestamp.fromDate(input.checkInAt),
          shiftName: input.shiftName,
          note: input.note,
          kioskEntry: false,
          source: "manager-group",
          createdAt: FieldValue.serverTimestamp(),
        }),
      );
      tx.create(batchRef, {
        id: batchId,
        fingerprint,
        organizationId: branch.organizationId,
        branchId: branch.id,
        workDate: input.workDate,
        shiftName: input.shiftName,
        attendeeCount: attendees.length,
        createdById: actor.uid,
        createdAt: FieldValue.serverTimestamp(),
        note: input.note,
      });
    });
    return { entryIds: refs.map((ref) => ref.id) };
  }),
);
