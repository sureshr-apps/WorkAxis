import assert from "node:assert/strict";
import { afterEach, beforeEach, it } from "node:test";
import { setDbForTests } from "../db";
import { FakeDb } from "./fakeDb";
import { capacityDb } from "./licenseFixtures";
import { DomainError } from "../errors";
import { parseBranchSave } from "../branches/savePlan";
import {
  branchCreation,
  commitBranchSave,
  loadBranchManagers,
} from "../sql/branchSave";

const actor = {
  uid: "admin",
  role: "orgAdmin" as const,
  organizationId: "o1",
  branchIds: [],
};
const draft = {
  name: "Branch",
  code: "B1",
  location: "City",
  status: "active",
  isMainBranch: false,
  geofenceRadiusMeters: 100,
  latitude: 12.9716,
  longitude: 77.5946,
  managerIds: [] as string[],
};

const createPlan = (managerIds: string[] = []) =>
  parseBranchSave(actor, { ...draft, requestId: "r1", managerIds });
const updatePlan = (managerIds: string[] = []) =>
  parseBranchSave(actor, { ...draft, id: "b1", managerIds });

const BRANCH_LOCK = "FROM branch WHERE id = $1 FOR UPDATE";

/** A database where every guard passes for an update of b1 with no managers. */
function happyDb(): FakeDb {
  // An active branch that stays active needs no capacity check.
  return new FakeDb().when(BRANCH_LOCK, [{ organizationId: "o1", status: "active" }]);
}

let db: FakeDb;
beforeEach(() => {
  db = happyDb();
  setDbForTests(db);
});
afterEach(() => setDbForTests(undefined));

const sqlOf = () => db.calls.map((c) => c.sql.replace(/\s+/g, " "));

async function failureOf(p: Promise<unknown>): Promise<[string, string]> {
  try {
    await p;
  } catch (e) {
    assert.ok(e instanceof DomainError, String(e));
    return [e.code, e.message];
  }
  assert.fail("expected a DomainError");
}

it("update runs every statement in one transaction and replaces manager assignments", async () => {
  db.when('AS "authUid" FROM organization_member', [
    { id: "m1", authUid: "u1" },
  ]);
  await commitBranchSave(updatePlan(["m1"]), []);
  assert.equal(db.transactions, 1);
  const sql = sqlOf();
  assert.ok(sql.some((s) => s.startsWith("UPDATE branch SET")));
  assert.ok(!sql.some((s) => s.startsWith("INSERT INTO branch")));
  const del = sql.findIndex((s) =>
    s.startsWith("DELETE FROM user_branch_assignment"),
  );
  const ins = sql.findIndex((s) =>
    s.startsWith("INSERT INTO user_branch_assignment"),
  );
  assert.ok(del > 0 && ins > del);
  assert.deepEqual(db.calls[ins].params, [["m1"], "b1"]);
});

it("create inserts the branch with idempotency columns instead of upserting", async () => {
  setDbForTests((db = capacityDb().when(BRANCH_LOCK, [])));
  const plan = createPlan();
  await commitBranchSave(plan, []);
  const insert = db.calls.find((c) => c.sql.startsWith("INSERT INTO branch"));
  assert.ok(insert);
  assert.match(insert.sql, /creation_request_key, creation_fingerprint/);
  assert.match(insert.sql, /, created_at\)/);
  assert.ok(insert.params.includes(plan.data.id));
  assert.ok(insert.params.includes(plan.creationFingerprint));
  assert.equal(db.transactions, 1);
});

it("creating over an existing branch fails with Branch not found", async () => {
  assert.deepEqual(await failureOf(commitBranchSave(createPlan(), [])), [
    "not-found",
    "Branch not found.",
  ]);
  assert.ok(!sqlOf().some((s) => s.startsWith("INSERT INTO branch")));
});

it("updating a missing or foreign branch fails with Branch not found", async () => {
  setDbForTests(new FakeDb());
  assert.equal(
    (await failureOf(commitBranchSave(updatePlan(), [])))[1],
    "Branch not found.",
  );
  setDbForTests(new FakeDb().when(BRANCH_LOCK, [{ organizationId: "o2" }]));
  assert.equal(
    (await failureOf(commitBranchSave(updatePlan(), [])))[1],
    "Branch not found.",
  );
});

it("rejects wanted managers that are missing, wrong-org/role, or have no auth uid", async () => {
  db.when('AS "authUid" FROM organization_member', [
    { id: "m1", authUid: null },
  ]);
  assert.deepEqual(await failureOf(commitBranchSave(updatePlan(["m1"]), [])), [
    "invalid-argument",
    "Invalid manager selection.",
  ]);
  setDbForTests(happyDb());
  assert.equal(
    (await failureOf(commitBranchSave(updatePlan(["m1"]), [])))[1],
    "Invalid manager selection.",
  );
});

it("rejects when the current assignment set differs from the caller's view", async () => {
  db.when('AS "memberId"', [{ memberId: "m9" }]);
  assert.deepEqual(await failureOf(commitBranchSave(updatePlan(), ["m1"])), [
    "failed-precondition",
    "Assignments changed. Reload the branch.",
  ]);
  assert.ok(!sqlOf().some((s) => s.startsWith("UPDATE branch")));
  setDbForTests(happyDb().when('AS "memberId"', [{ memberId: "m1" }]));
  assert.equal(
    (await failureOf(commitBranchSave(updatePlan(), [])))[1],
    "Assignments changed. Reload the branch.",
  );
});

it("rejects removing a manager who would have no branch left", async () => {
  db.when('AS "memberId"', [{ memberId: "m1" }]);
  db.when('"otherBranches"', [{ id: "m1", otherBranches: 0 }]);
  assert.deepEqual(await failureOf(commitBranchSave(updatePlan(), ["m1"])), [
    "invalid-argument",
    "A manager must keep at least one branch.",
  ]);
  assert.ok(!sqlOf().some((s) => s.startsWith("UPDATE branch")));
});

it("allows removing a manager who keeps another branch (count arrives as a string)", async () => {
  db.when('AS "memberId"', [{ memberId: "m1" }]);
  db.when('"otherBranches"', [{ id: "m1", otherBranches: "2" }]);
  await commitBranchSave(updatePlan(), ["m1"]);
  assert.ok(sqlOf().some((s) => s.startsWith("UPDATE branch SET")));
});

it("branchCreation maps the row and returns null when absent", async () => {
  const row = { id: "b1", code: "B1", creationFingerprint: "fp" };
  setDbForTests(new FakeDb().when("FROM branch WHERE id", [row]));
  assert.deepEqual(await branchCreation("b1"), row);
  setDbForTests(new FakeDb());
  assert.equal(await branchCreation("b1"), null);
});

it("loadBranchManagers groups assignment rows per manager", async () => {
  const base = { authUid: "u", organizationId: "o1", role: "branchManager" };
  setDbForTests(
    new FakeDb().when("LEFT JOIN user_branch_assignment", [
      { ...base, id: "m1", branchId: "b1" },
      { ...base, id: "m1", branchId: "b2" },
      { ...base, id: "m2", branchId: null },
    ]),
  );
  const managers = await loadBranchManagers("o1");
  assert.deepEqual(
    managers.map((m) => [m.id, m.branchIds]),
    [
      ["m1", ["b1", "b2"]],
      ["m2", []],
    ],
  );
});
