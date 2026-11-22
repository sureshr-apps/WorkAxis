import { createHash } from "node:crypto";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { resolveActor } from "../auth/actor";
import {
  assertGroupAttendee,
  assertGroupScope,
  parseGroupAttendance,
} from "../attendance/groupRules";
import { assertScheduledWorkday } from "../attendance/punchRules";
import { callableOptions } from "../config";
import { conflict, guarded, notFound } from "../errors";
import { getDb } from "../db";
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
    const database = await getDb();
    const memberIds = attendees.map((member) => member.id);
    const scheduleRows = await database.query<{
      memberId: string;
      weeklyDayOff: number;
    }>(
      `SELECT DISTINCT ON (member_id) member_id AS "memberId",
              weekly_day_off AS "weeklyDayOff"
         FROM employee_schedule_history
        WHERE member_id = ANY($1::text[]) AND effective_from <= $2::date
          AND (effective_to IS NULL OR effective_to > $2::date)
        ORDER BY member_id, effective_from DESC`,
      [memberIds, input.workDate],
    );
    const dayOffByMember = new Map(scheduleRows.map((row) => [row.memberId, Number(row.weeklyDayOff)]));
    for (const member of attendees) assertScheduledWorkday(input.workDate, dayOffByMember.get(member.id) ?? 0);
    const batchId = `${actor.uid}_${input.requestId}`;
    const batchRef = firestore
      .collection("group_attendance_batches")
      .doc(batchId);
    const fingerprint = createHash("sha256")
      .update(JSON.stringify(input))
      .digest("hex");
    const entries = firestore.collection("attendance_entries");
    const refs = attendees.map((member) =>
      entries.doc(`${member.authUid}_${input.workDate}_${actor.uid}_${input.requestId}`),
    );
    const legacyRefs = attendees.map((member) =>
      entries.doc(`${member.authUid}_${input.workDate}`),
    );
    const stateRefs = attendees.map((member) =>
      firestore.collection("attendance_session_state")
        .doc(`${member.authUid}_${input.workDate}`),
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
      const states = await Promise.all(stateRefs.map((ref) => tx.get(ref)));
      const legacy = await Promise.all(legacyRefs.map((ref) => tx.get(ref)));
      if (states.some((doc) => doc.exists && doc.get("activeEntryId")) ||
          legacy.some((doc) => doc.exists && doc.get("checkInAt") && !doc.get("checkOutAt")))
        throw conflict(
          "Some selected employees already have an open attendance session.",
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
      attendees.forEach((member, index) =>
        tx.set(stateRefs[index], {
          employeeId: member.authUid,
          workDateString: input.workDate,
          activeEntryId: refs[index].id,
          branchId: branch.id,
          updatedAt: FieldValue.serverTimestamp(),
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
