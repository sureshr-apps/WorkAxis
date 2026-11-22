import assert from "node:assert/strict";
import { test } from "node:test";
import { assertPunchAllowed, assertScheduledWorkday } from "../attendance/punchRules";

test("weekly days off block every attendance punch by business date", () => {
  assert.throws(() => assertScheduledWorkday("2026-11-22", 0)); // Sunday
  assert.doesNotThrow(() => assertScheduledWorkday("2026-11-23", 0));
  assert.throws(() => assertScheduledWorkday("2026-11-23", 1)); // Monday
});

test("a new session may start after an earlier session is closed", () => {
  // assertPunchAllowed validates one session. The guard document decides
  // whether another session is currently open for this employee/day.
  assert.doesNotThrow(() =>
    assertPunchAllowed("checkIn", {
      breaks: [],
    }),
  );
});

test("a second check-in is rejected while its session is still open", () => {
  assert.throws(() =>
    assertPunchAllowed("checkIn", {
      checkInAt: new Date("2026-11-22T03:00:00Z"),
      breaks: [],
    }),
  );
});
