import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { approvedOvertimeHours, validateRequestedCheckOut, type CorrectableEntry } from "../attendance/corrections";
import { potentialOvertimeBySession, workedHours } from "../attendance/overtime";
import { attendanceTiming, sessionDeadlines, DEFAULT_ATTENDANCE_TIMING } from "../attendance/sessionPolicy";
import { parseShiftHours, resolveShift, shiftOn, type ScheduleSpan } from "../attendance/shiftWindow";
import { DomainError } from "../errors";

// Times are Asia/Kolkata (+05:30). 23 Nov 2026 is a Monday.
const ist = (local: string) => new Date(`${local}+05:30`);
const day: ScheduleSpan = {
  effectiveFrom: "2026-01-01",
  shiftHours: "09:00 AM - 05:00 PM",
  dailyWorkHours: 8,
  weeklyDaysOff: [0],
};
const night: ScheduleSpan = { ...day, shiftHours: "09:00 PM - 05:00 AM" };
const EARLY = DEFAULT_ATTENDANCE_TIMING.earlyCheckInMinutes;
const code = (expected: string) => (e: unknown) => e instanceof DomainError && e.code === expected;

describe("shift windows", () => {
  it("parses day and overnight shifts", () => {
    assert.deepEqual(parseShiftHours("09:00 AM - 05:00 PM"), { startMinutes: 540, durationMinutes: 480 });
    assert.deepEqual(parseShiftHours("09:00 PM - 05:00 AM"), { startMinutes: 1260, durationMinutes: 480 });
  });

  it("places a night shift on the day it starts and ends it the next morning", () => {
    const window = shiftOn([night], "2026-11-23")!;
    assert.equal(window.startAt.getTime(), ist("2026-11-23T21:00:00").getTime());
    assert.equal(window.endAt.getTime(), ist("2026-11-24T05:00:00").getTime());
  });

  it("assigns day-shift check-ins to their calendar date", () => {
    assert.equal(resolveShift(ist("2026-11-23T08:55:00"), [day], EARLY).shiftDate, "2026-11-23");
    // Outside the window (very early) still belongs to the calendar date.
    const early = resolveShift(ist("2026-11-23T05:00:00"), [day], EARLY);
    assert.equal(early.shiftDate, "2026-11-23");
    assert.equal(early.window?.shiftDate, "2026-11-23");
  });

  it("keeps a night shift on the day it began, even for a check-in after midnight", () => {
    assert.equal(resolveShift(ist("2026-11-23T20:30:00"), [night], EARLY).shiftDate, "2026-11-23");
    // Arriving late at 00:30 on Tuesday still belongs to Monday's shift.
    assert.equal(resolveShift(ist("2026-11-24T00:30:00"), [night], EARLY).shiftDate, "2026-11-23");
    // A check-in earlier than the early window belongs to its calendar date.
    assert.equal(resolveShift(ist("2026-11-23T15:00:00"), [night], EARLY).shiftDate, "2026-11-23");
  });

  it("lets a night shift that ends on a day off check in, and refuses a day off otherwise", () => {
    // Saturday 21 Nov night shift ends on Sunday (day off): the check-in is Saturday's.
    assert.equal(resolveShift(ist("2026-11-21T21:00:00"), [night], EARLY).shiftDate, "2026-11-21");
    // Sunday evening is not within any shift: Sunday is the day off.
    assert.throws(() => resolveShift(ist("2026-11-22T12:00:00"), [day], EARLY), code("failed-precondition"));
    // Without any schedule, Sunday stays off.
    assert.throws(() => resolveShift(ist("2026-11-22T12:00:00"), [], EARLY), code("failed-precondition"));
    assert.equal(resolveShift(ist("2026-11-23T12:00:00"), [], EARLY).window, null);
  });

  it("prefers the nearest shift when two windows overlap", () => {
    const early: ScheduleSpan = { ...day, shiftHours: "06:00 AM - 02:00 PM", weeklyDaysOff: [] };
    const versions = [
      { ...night, weeklyDaysOff: [], effectiveTo: "2026-11-24" },
      { ...early, effectiveFrom: "2026-11-24" },
    ];
    // 04:30 Tuesday is inside Monday's night shift and Tuesday's early window.
    assert.equal(resolveShift(ist("2026-11-24T04:30:00"), versions, EARLY).shiftDate, "2026-11-24");
  });
});

describe("session deadlines", () => {
  it("separates shift end, reminder, overdue and expiry", () => {
    const window = shiftOn([day], "2026-11-23")!;
    const d = sessionDeadlines(ist("2026-11-23T09:00:00"), window, DEFAULT_ATTENDANCE_TIMING);
    assert.equal(d.reminderAt?.getTime(), ist("2026-11-23T17:30:00").getTime());
    assert.equal(d.overdueAt?.getTime(), ist("2026-11-23T21:00:00").getTime());
    assert.equal(d.expiresAt.getTime(), ist("2026-11-24T01:00:00").getTime());
  });

  it("applies the same rules to a night shift across midnight", () => {
    const window = shiftOn([night], "2026-11-23")!;
    const d = sessionDeadlines(ist("2026-11-23T21:00:00"), window, DEFAULT_ATTENDANCE_TIMING);
    assert.equal(d.reminderAt?.getTime(), ist("2026-11-24T05:30:00").getTime());
    assert.equal(d.overdueAt?.getTime(), ist("2026-11-24T09:00:00").getTime());
    assert.equal(d.expiresAt.getTime(), ist("2026-11-24T13:00:00").getTime());
  });

  it("only expires an unscheduled session and drops deadlines past the expiry", () => {
    const unscheduled = sessionDeadlines(ist("2026-11-23T09:00:00"), null, DEFAULT_ATTENDANCE_TIMING);
    assert.equal(unscheduled.reminderAt, null);
    assert.equal(unscheduled.overdueAt, null);
    // Checked in at noon with an 8-hour limit: expiry at 8 PM comes before
    // the 9 PM overdue time, so no overdue flag is scheduled.
    const late = sessionDeadlines(
      ist("2026-11-23T12:00:00"),
      shiftOn([day], "2026-11-23"),
      { ...DEFAULT_ATTENDANCE_TIMING, maxSessionHours: 8 },
    );
    assert.equal(late.overdueAt, null);
  });

  it("reads timing settings with defaults for missing or invalid values", () => {
    assert.deepEqual(attendanceTiming(undefined), DEFAULT_ATTENDANCE_TIMING);
    assert.deepEqual(
      attendanceTiming({ earlyCheckInMinutes: 60, maxSessionHours: 30, overtimeReviewMinutes: 1.5 }),
      { ...DEFAULT_ATTENDANCE_TIMING, earlyCheckInMinutes: 60 },
    );
  });
});

describe("overtime", () => {
  it("is worked time beyond the schedule, less breaks, split across sessions", () => {
    const at = (h: number) => ist(`2026-11-23T${String(h).padStart(2, "0")}:00:00`);
    assert.equal(workedHours(at(9), at(19), [{ startAt: at(13), endAt: at(14) }]), 9);
    const split = potentialOvertimeBySession([
      { id: "b", checkInAt: at(15), checkOutAt: at(19), breaks: [] },
      { id: "a", checkInAt: at(8), checkOutAt: at(14), breaks: [] },
    ], 8);
    // 6 hours then 4 more: the second session carries the 2 hours over 8.
    assert.deepEqual(Object.fromEntries(split), { a: 0, b: 2 });
  });

  it("approves up to the potential hours with at most two decimals", () => {
    assert.equal(approvedOvertimeHours(2, undefined), 2);
    assert.equal(approvedOvertimeHours(2, 1.25), 1.25);
    assert.throws(() => approvedOvertimeHours(2, 2.5), code("invalid-argument"));
    assert.throws(() => approvedOvertimeHours(2, 1.255), code("invalid-argument"));
    assert.throws(() => approvedOvertimeHours(0, 1), code("failed-precondition"));
  });
});

describe("check-out corrections", () => {
  const entry = (over: Partial<CorrectableEntry> = {}): CorrectableEntry => ({
    checkInAt: ist("2026-11-23T21:00:00"),
    checkOutAt: null,
    breaks: [{ startAt: ist("2026-11-24T01:00:00"), endAt: ist("2026-11-24T01:30:00") }],
    checkoutStatus: "missing",
    correctionStatus: null,
    ...over,
  });
  const now = ist("2026-11-24T15:00:00");

  it("accepts the time an employee left after a night shift", () => {
    validateRequestedCheckOut(entry(), ist("2026-11-24T05:10:00"), now);
  });

  it("rejects impossible or duplicate corrections", () => {
    const reject = (over: Partial<CorrectableEntry>, at: string, expected: string) =>
      assert.throws(() => validateRequestedCheckOut(entry(over), ist(at), now), code(expected));
    reject({ checkoutStatus: "none" }, "2026-11-24T05:00:00", "failed-precondition");
    reject({ correctionStatus: "pending" }, "2026-11-24T05:00:00", "already-exists");
    reject({}, "2026-11-23T20:00:00", "invalid-argument"); // before check-in
    reject({}, "2026-11-24T01:15:00", "invalid-argument"); // during the last break
    reject({}, "2026-11-24T16:00:00", "invalid-argument"); // in the future
    reject({ checkoutStatus: "late", checkOutAt: ist("2026-11-24T10:00:00") }, "2026-11-24T11:00:00", "invalid-argument");
  });
});
