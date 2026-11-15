import assert from "node:assert/strict";
import { afterEach, it } from "node:test";
import { setDbForTests } from "../db";
import { FakeDb } from "./fakeDb";
import {
  deleteOrganizationSql,
  ORGANIZATION_DELETE_STEPS,
} from "../sql/branches";

afterEach(() => setDbForTests(undefined));

it("runs the eight delete steps in order, each scoped to the organization", async () => {
  const db = new FakeDb();
  setDbForTests(db);
  await deleteOrganizationSql("o1");
  assert.deepEqual(
    db.calls.map((c) => c.sql),
    ORGANIZATION_DELETE_STEPS.map((s) => s.sql),
  );
  assert.ok(
    db.calls.every((c) => c.params.length === 1 && c.params[0] === "o1"),
  );
  const tables = db.calls.map((c) => /DELETE FROM (\w+)/.exec(c.sql)![1]);
  assert.deepEqual(tables, [
    "user_branch_assignment",
    "user_branch_assignment",
    "return_record",
    "commercial_agreement",
    "license_event",
    "branch",
    "organization_member",
    "organization",
  ]);
});

it("stops and rethrows when a step fails", async () => {
  const db = new FakeDb().whenCall((c) => {
    if (/DELETE FROM branch\s/.test(c.sql)) throw new Error("boom");
    return undefined;
  });
  setDbForTests(db);
  await assert.rejects(deleteOrganizationSql("o1"), /boom/);
  assert.equal(db.calls.length, 6);
});
