// Emulator tests for the server-side attendance session handling (admin SDK,
// rules do not apply). Run with the Firestore emulator:
//   firebase emulators:exec --only firestore "npm --prefix functions run test:rules"
import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { after, beforeEach, describe, it } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { Timestamp, getFirestore } from "firebase-admin/firestore";

const require = createRequire(import.meta.url);
const { sweepAttendanceSessions } = require("../lib/attendance/sessionSweep.js");
const { recomputeDayOvertime } = require("../lib/attendance/attendanceStore.js");

const PROJECT = "workaxis-sessions-test";
const app = initializeApp({ projectId: PROJECT }, "attendance-sessions-test");
const firestore = getFirestore(app);
const ist = (local) => new Date(`${local}+05:30`);
const stamp = (local) => Timestamp.fromDate(ist(local));

async function clear() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  assert.ok(host, "FIRESTORE_EMULATOR_HOST must be set (run under emulators:exec)");
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, {
    method: "DELETE",
  });
}

/** A Monday 9 PM to Tuesday 5 AM night session, still open. */
async function seedOpenNightShift() {
  await firestore.doc("attendance_entries/night").set({
    organizationId: "o1",
    branchId: "b1",
    employeeId: "emp",
    workDateString: "2026-11-23",
    status: "present",
    reviewStatus: "none",
    checkInAt: stamp("2026-11-23T21:00:00"),
    breaks: [],
    open: true,
    scheduledHours: 8,
    checkoutStatus: "none",
    overtimeStatus: "none",
    checkoutOverdueAt: stamp("2026-11-24T09:00:00"),
    sessionExpiresAt: stamp("2026-11-24T13:00:00"),
  });
  await firestore.doc("attendance_session_state/emp").set({
    employeeId: "emp",
    organizationId: "o1",
    branchId: "b1",
    activeEntryId: "night",
    workDateString: "2026-11-23",
    checkInAt: stamp("2026-11-23T21:00:00"),
    checkoutOverdueAt: stamp("2026-11-24T09:00:00"),
    overdueFlagged: false,
    sessionExpiresAt: stamp("2026-11-24T13:00:00"),
  });
}

beforeEach(clear);
after(async () => deleteApp(app));

describe("attendance session sweep", () => {
  it("does nothing while the shift is still within its allowance", async () => {
    await seedOpenNightShift();
    const result = await sweepAttendanceSessions(firestore, ist("2026-11-24T08:59:00"));
    assert.deepEqual(result, { flaggedOverdue: 0, closedMissing: 0 });
    assert.equal((await firestore.doc("attendance_entries/night").get()).get("checkoutStatus"), "none");
  });

  it("flags an overdue check-out but keeps the session open", async () => {
    await seedOpenNightShift();
    const result = await sweepAttendanceSessions(firestore, ist("2026-11-24T09:05:00"));
    assert.deepEqual(result, { flaggedOverdue: 1, closedMissing: 0 });
    const entry = (await firestore.doc("attendance_entries/night").get()).data();
    assert.equal(entry.checkoutStatus, "overdue");
    assert.equal(entry.reviewStatus, "needsReview");
    assert.equal(entry.open, true);
    const state = await firestore.doc("attendance_session_state/emp").get();
    assert.equal(state.get("overdueFlagged"), true);
    // A second run does not flag it again.
    const again = await sweepAttendanceSessions(firestore, ist("2026-11-24T09:20:00"));
    assert.equal(again.flaggedOverdue, 0);
  });

  it("closes an expired session as a missing check-out without inventing one", async () => {
    await seedOpenNightShift();
    const result = await sweepAttendanceSessions(firestore, ist("2026-11-24T13:01:00"));
    assert.equal(result.closedMissing, 1);
    const entry = (await firestore.doc("attendance_entries/night").get()).data();
    assert.equal(entry.checkOutAt, undefined);
    assert.equal(entry.open, false);
    assert.equal(entry.status, "incomplete");
    assert.equal(entry.checkoutStatus, "missing");
    assert.equal(entry.reviewStatus, "needsReview");
    assert.equal(entry.sessionClosure.closedBy, "system");
    assert.equal(entry.sessionClosure.reason, "maxSessionExceeded");
    assert.ok(entry.sessionClosure.closedAt instanceof Timestamp);
    // The employee is free to check in again.
    assert.equal((await firestore.doc("attendance_session_state/emp").get()).exists, false);
  });
});

describe("day overtime recompute", () => {
  it("credits overtime to the session that crosses the schedule and caps approvals", async () => {
    // Shift date 23 Nov, 8 scheduled hours: 9 AM-3 PM, then 4 PM-7 PM (being checked out).
    await firestore.doc("attendance_entries/first").set({
      organizationId: "o1", employeeId: "emp", workDateString: "2026-11-23",
      checkInAt: stamp("2026-11-23T09:00:00"), checkOutAt: stamp("2026-11-23T15:00:00"),
      breaks: [], scheduledHours: 8, overtimeStatus: "none", potentialOvertimeHours: 0,
    });
    await firestore.doc("attendance_entries/second").set({
      organizationId: "o1", employeeId: "emp", workDateString: "2026-11-23",
      checkInAt: stamp("2026-11-23T16:00:00"),
      breaks: [], scheduledHours: 8, overtimeStatus: "none", potentialOvertimeHours: 0,
    });
    await firestore.runTransaction((tx) => recomputeDayOvertime(firestore, tx, "emp", "o1", "2026-11-23", {
      id: "second",
      checkOutAt: ist("2026-11-23T19:00:00"),
      extra: { checkOutAt: stamp("2026-11-23T19:00:00"), open: false },
    }));
    const second = (await firestore.doc("attendance_entries/second").get()).data();
    assert.equal(second.potentialOvertimeHours, 1);
    assert.equal(second.overtimeStatus, "pending");
    assert.equal(second.open, false);
    assert.equal((await firestore.doc("attendance_entries/first").get()).get("potentialOvertimeHours"), 0);

    // An approval of 1 hour, then a correction shortening the first session to
    // 2 PM: overtime drops to 0, so the approval is withdrawn.
    await firestore.doc("attendance_entries/second").update({ overtimeStatus: "approved", approvedOvertimeHours: 1 });
    await firestore.runTransaction((tx) => recomputeDayOvertime(firestore, tx, "emp", "o1", "2026-11-23", {
      id: "first",
      checkOutAt: ist("2026-11-23T14:00:00"),
      extra: { checkOutAt: stamp("2026-11-23T14:00:00") },
    }));
    const after = (await firestore.doc("attendance_entries/second").get()).data();
    assert.equal(after.potentialOvertimeHours, 0);
    assert.equal(after.overtimeStatus, "none");
    assert.equal(after.approvedOvertimeHours, undefined);
  });
});
