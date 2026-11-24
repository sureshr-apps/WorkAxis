import assert from "node:assert/strict";
import { test } from "node:test";
import type { Actor } from "../auth/roles";
import { runOperation } from "../data/dispatch";
import { operations } from "../data/registry";
import { FakeDb } from "./fakeDb";

const orgAdmin: Actor = {
  uid: "admin-1",
  role: "orgAdmin",
  organizationId: "org-1",
  branchIds: [],
};

const branchManager: Actor = {
  uid: "manager-1",
  role: "branchManager",
  organizationId: "org-1",
  branchIds: ["branch-1"],
};

function run(db: FakeDb, actor: Actor, op: string, vars: Record<string, unknown>) {
  return runOperation(
    operations,
    { db, actor, requireEmployeeAssetAcknowledgement: async () => false },
    { op, vars },
  );
}

test("organization dashboard counts only employees scheduled today", async () => {
  const db = new FakeDb().when("from employee_schedule_history h", [
    { _count: "8" },
  ]);

  const result = (await run(db, orgAdmin, "GetOrganizationDashboardCounts", {
    orgId: "org-1",
  })) as { scheduledEmployeeCount: { _count: number }[] };

  const scheduleQuery = db.calls.find((call) =>
    call.sql.toLowerCase().includes("from employee_schedule_history h"),
  );
  assert.ok(scheduleQuery);
  assert.match(scheduleQuery.sql, /Asia\/Kolkata/);
  assert.match(scheduleQuery.sql, /effective_from <= d\.today/);
  assert.match(scheduleQuery.sql, /effective_to > d\.today/);
  assert.match(scheduleQuery.sql, /weekly_days_off/);
  assert.deepEqual(scheduleQuery.params, ["org-1"]);
  assert.deepEqual(result.scheduledEmployeeCount, [{ _count: 8 }]);
});

test("branch dashboard counts scheduled employees only in that branch", async () => {
  const db = new FakeDb()
    .when("from branch where", [{ id: "branch-1", organizationId: "org-1" }])
    .when("from employee_schedule_history h", [{ _count: "3" }]);

  const result = (await run(db, branchManager, "GetBranchStats", {
    branchId: "branch-1",
  })) as { scheduledMemberCount: { _count: number }[] };

  const scheduleQuery = db.calls.find((call) =>
    call.sql.toLowerCase().includes("from employee_schedule_history h"),
  );
  assert.ok(scheduleQuery);
  assert.match(scheduleQuery.sql, /a\.branch_id = \$1/);
  assert.match(scheduleQuery.sql, /weekly_days_off/);
  assert.deepEqual(scheduleQuery.params, ["branch-1"]);
  assert.deepEqual(result.scheduledMemberCount, [{ _count: 3 }]);
});
