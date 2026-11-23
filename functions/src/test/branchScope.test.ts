import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { Actor } from "../auth/roles";
import {
  findActiveBranch,
  requireActiveBranch,
  requireBranchManagerContext,
} from "../data/authz";
import { runOperation } from "../data/dispatch";
import { operations } from "../data/registry";
import { notFound } from "../errors";
import { FakeDb } from "./fakeDb";

const manager: Actor = { uid: "m1", role: "branchManager", organizationId: "o1", branchIds: ["b1", "b2"] };
const orgAdmin: Actor = { uid: "a1", role: "orgAdmin", organizationId: "o1", branchIds: [] };
const employee: Actor = { uid: "e1", role: "employee", organizationId: "o1", branchIds: ["b1"] };

const code = (expected: string) => (e: { code?: string }) => e.code === expected;

describe("active branch helpers", () => {
  it("looks up only active branches of the given organization", async () => {
    const db = new FakeDb().when("from branch where id", [{ id: "b1", name: "Main" }]);
    assert.deepEqual(await findActiveBranch(db, "b1", "o1"), { id: "b1", name: "Main" });
    const query = db.calls[0];
    assert.match(query.sql, /status = 'active'/);
    assert.deepEqual(query.params, ["b1", "o1"]);
  });

  it("never queries without an organization", async () => {
    const db = new FakeDb();
    assert.equal(await findActiveBranch(db, "b1", undefined), null);
    assert.equal(db.calls.length, 0);
  });

  it("denies a missing or inactive branch, or raises the caller's error", async () => {
    await assert.rejects(requireActiveBranch(new FakeDb(), "b1", "o1"), code("permission-denied"));
    await assert.rejects(
      requireActiveBranch(new FakeDb(), "b1", "o1", () => notFound("Branch not found.")),
      code("not-found"),
    );
  });

  it("holds Branch Managers to their selected, assigned branch", () => {
    requireBranchManagerContext(manager, { activeBranchId: "b1" }, "b1");
    requireBranchManagerContext(orgAdmin, {}, "b9");
    assert.throws(
      () => requireBranchManagerContext(manager, { activeBranchId: "b2" }, "b1", "Use the active branch."),
      (e: { code?: string; message?: string }) =>
        e.code === "permission-denied" && e.message === "Use the active branch.",
    );
    assert.throws(
      () => requireBranchManagerContext(manager, { activeBranchId: "b9" }, "b9"),
      code("permission-denied"),
    );
    assert.throws(() => requireBranchManagerContext(manager, {}, "b1"), code("invalid-argument"));
  });

  it("rejects a return filed against an inactive branch", async () => {
    // The active-branch query filters by status, so an inactive branch yields no row.
    const db = new FakeDb().when("from organization_member where auth_uid", [
      { id: "mem1", authUid: "e1", fullName: "Eve" },
    ]);
    await assert.rejects(
      runOperation(
        operations,
        { db, actor: employee, requireEmployeeAssetAcknowledgement: async () => false },
        {
          op: "SubmitReturn",
          vars: {
            branchId: "b1", productTitle: "Shoe", returnReason: "Torn", quantity: 1, unit: "pc",
            invoiceNumber: "INV1",
          },
        },
      ),
      (e: { code?: string; message?: string }) =>
        e.code === "permission-denied" && e.message === "Branch not found or inactive.",
    );
    assert.ok(!db.calls.some((c) => /insert into return_record/i.test(c.sql)));
  });
});
