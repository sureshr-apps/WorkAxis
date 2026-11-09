import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  assertGroupAttendee,
  assertGroupScope,
  parseGroupAttendance,
} from "../attendance/groupRules";
import type { Actor } from "../auth/roles";
import type { MemberRecord } from "../sql/members";

const now = new Date("2026-11-07T05:00:00Z");
const input = {
  requestId: "req-1",
  branchId: "b1",
  workDate: "2026-11-07",
  checkInAt: "2026-11-07T08:30:00+05:30",
  employeeIds: ["e1"],
  status: "present",
  shiftName: "Morning",
};
const actor: Actor = {
  uid: "manager",
  role: "branchManager",
  organizationId: "o1",
  branchIds: ["b1"],
};
const member: MemberRecord = {
  id: "m1",
  authUid: "e1",
  fullName: "Employee",
  username: "employee",
  email: "employee@login.workaxis.invalid",
  role: "employee",
  status: "active",
  organizationId: "o1",
  organizationStatus: "active",
  branchIds: ["b1"],
  activeBranchIds: ["b1"],
};

describe("trusted group attendance", () => {
  it("converts the selected effective time with an explicit timezone", () => {
    assert.equal(
      parseGroupAttendance(input, now).checkInAt.toISOString(),
      "2026-11-07T03:00:00.000Z",
    );
  });
  it("rejects future, mismatched, invalid and timezone-ambiguous effective times", () => {
    for (const checkInAt of [
      "2026-11-07T12:00:00+05:30",
      "2026-11-06T08:30:00+05:30",
      "not-a-date",
      "2026-11-07T08:30:00",
    ]) {
      assert.throws(() => parseGroupAttendance({ ...input, checkInAt }, now));
    }
    for (const workDate of ["2026-11-08", "2026-10-31", "2026-02-30"]) {
      assert.throws(() => parseGroupAttendance({ ...input, workDate }, now));
    }
  });
  it("accepts the sixth previous business day", () => {
    assert.equal(
      parseGroupAttendance(
        {
          ...input,
          workDate: "2026-11-01",
          checkInAt: "2026-11-01T08:00:00+05:30",
        },
        now,
      ).workDate,
      "2026-11-01",
    );
  });
  it("rejects duplicate, missing, oversized and path-like employee ids", () => {
    for (const employeeIds of [
      [],
      ["e1", "e1"],
      ["foreign/path"],
      Array.from({ length: 401 }, (_, i) => `e${i}`),
    ]) {
      assert.throws(() => parseGroupAttendance({ ...input, employeeIds }, now));
    }
  });
  it("checks the caller against the active branch and organization", () => {
    const branch = { id: "b1", organizationId: "o1", status: "active" };
    assert.doesNotThrow(() => assertGroupScope(actor, branch));
    assert.throws(() => assertGroupScope(actor, { ...branch, id: "b2" }));
    assert.throws(() =>
      assertGroupScope(actor, { ...branch, organizationId: "o2" }),
    );
    assert.throws(() =>
      assertGroupScope({ ...actor, role: "employee" }, branch),
    );
    assert.throws(() =>
      assertGroupScope(actor, { ...branch, status: "suspended" }),
    );
  });
  it("rejects foreign, unassigned, suspended and non-employee attendees", () => {
    assert.doesNotThrow(() => assertGroupAttendee(member, "o1", "b1"));
    for (const candidate of [
      null,
      { ...member, organizationId: "o2" },
      { ...member, activeBranchIds: ["b2"] },
      { ...member, status: "suspended" as const },
      { ...member, role: "branchManager" as const },
      { ...member, organizationStatus: "suspended" },
    ]) {
      assert.throws(() => assertGroupAttendee(candidate, "o1", "b1"));
    }
  });
});
