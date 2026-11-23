import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { Actor } from "../auth/roles";
import { runOperation } from "../data/dispatch";
import { operations } from "../data/registry";
import { FakeDb } from "./fakeDb";

const orgAdmin: Actor = { uid: "a1", role: "orgAdmin", organizationId: "o1", branchIds: [] };
const manager: Actor = { uid: "m1", role: "branchManager", organizationId: "o1", branchIds: ["b1"] };
const employee: Actor = { uid: "e1", role: "employee", organizationId: "o1", branchIds: ["b1"] };

function run(db: FakeDb, actor: Actor, op: string, vars: Record<string, unknown> = {}) {
  return runOperation(
    operations,
    { db, actor, requireEmployeeAssetAcknowledgement: async () => false },
    { op, vars },
  );
}

const isCode = (code: string) => (e: { code?: string }) => e.code === code;
const TODAY = /^\d{4}-\d{2}-\d{2}$/;

describe("leave policy operations", () => {
  it("lists active types to every organization member, but policy only to admins", async () => {
    const db = () => new FakeDb().when("from leave_type t", [
      { id: "t1", name: "Annual leave", paid: true, yearlyDays: 12, carryForward: false },
    ]);
    for (const actor of [employee, manager, orgAdmin]) {
      const res = (await run(db(), actor, "ListLeaveTypes")) as { leaveTypes: unknown[] };
      assert.deepEqual(res.leaveTypes, [{ id: "t1", name: "Annual leave", paid: true }]);
    }
    await assert.rejects(run(db(), manager, "GetLeavePolicy"), isCode("permission-denied"));
    await assert.rejects(run(db(), employee, "SaveLeaveType", {
      name: "X", yearlyDays: 1, carryForward: false,
    }), isCode("permission-denied"));
  });

  it("creates a type with an allowance effective today", async () => {
    const db = new FakeDb()
      .when("insert into leave_type (", [{ id: "t9" }])
      .when("from leave_type t", [{ id: "t9", name: "Study leave", paid: true, yearlyDays: 4, carryForward: true }]);
    const res = await run(db, orgAdmin, "SaveLeaveType", {
      name: " Study leave ", yearlyDays: 4, carryForward: true,
    });
    assert.deepEqual(res, {
      leaveType: { id: "t9", name: "Study leave", paid: true, yearlyDays: 4, carryForward: true },
    });
    const allowance = db.calls.find((c) => /insert into leave_type_allowance/i.test(c.sql))!;
    assert.equal(allowance.params[0], "t9");
    assert.match(String(allowance.params[1]), TODAY);
    assert.deepEqual(allowance.params.slice(2, 4), [4, true]);
  });

  it("records a new allowance version only when the allowance changes", async () => {
    const existing = () => new FakeDb()
      .when("select paid from leave_type", [{ paid: true }])
      .when("from leave_type_allowance", [{ yearlyDays: 4, carryForward: false }]);
    const renamed = existing();
    await run(renamed, orgAdmin, "SaveLeaveType", { id: "t1", name: "Vacation", yearlyDays: 4, carryForward: false });
    assert.ok(!renamed.calls.some((c) => /insert into leave_type_allowance/i.test(c.sql)));
    const changed = existing();
    await run(changed, orgAdmin, "SaveLeaveType", { id: "t1", name: "Vacation", yearlyDays: 6, carryForward: false });
    assert.ok(changed.calls.some((c) => /insert into leave_type_allowance/i.test(c.sql)));
  });

  it("rejects duplicate names, bad allowances and an allowance on unpaid leave", async () => {
    const duplicate = new FakeDb().when("lower(btrim(name)) = lower($2)", [{ id: "other" }]);
    await assert.rejects(
      run(duplicate, orgAdmin, "SaveLeaveType", { name: "Sick leave", yearlyDays: 2, carryForward: false }),
      /already uses that name/,
    );
    for (const yearlyDays of [-1, 367, 1.005]) {
      await assert.rejects(
        run(new FakeDb(), orgAdmin, "SaveLeaveType", { name: "X", yearlyDays, carryForward: false }),
        isCode("invalid-argument"),
      );
    }
    const unpaidType = new FakeDb().when("select paid from leave_type", [{ paid: false }]);
    await assert.rejects(
      run(unpaidType, orgAdmin, "SaveLeaveType", { id: "u", name: "Unpaid leave", yearlyDays: 2, carryForward: false }),
      /no allowance/,
    );
  });

  it("archives only paid types of the caller's organization", async () => {
    const db = new FakeDb();
    await assert.rejects(run(db, orgAdmin, "ArchiveLeaveType", { id: "unpaid" }), isCode("not-found"));
    assert.match(db.calls[0].sql, /AND paid/);
    assert.deepEqual(db.calls[0].params, ["unpaid", "o1"]);
  });

  it("switches monthly accrual from today", async () => {
    const db = new FakeDb();
    const res = await run(db, orgAdmin, "SetLeaveAccrual", { monthlyAccrual: true });
    assert.deepEqual(res, { leavePolicy: { monthlyAccrual: true } });
    assert.match(db.calls[0].sql, /ON CONFLICT \(organization_id, effective_from\)/);
    assert.match(String(db.calls[0].params[1]), TODAY);
    await assert.rejects(
      run(new FakeDb(), orgAdmin, "SetLeaveAccrual", { monthlyAccrual: "yes" }),
      isCode("invalid-argument"),
    );
  });

  it("keeps a branch manager's review preview to their active branch employees", async () => {
    const request = {
      id: "r1", leaveTypeId: "t1", startDate: "2026-01-05", endDate: "2026-01-06",
      memberId: "mem", authUid: "u", branchId: "b2", applicantRole: "employee", organizationId: "o1",
    };
    const db = new FakeDb().when("from leave_request where id", [request]);
    await assert.rejects(
      run(db, manager, "PreviewLeaveRequest", { id: "r1", activeBranchId: "b2" }),
      isCode("not-found"),
    );
    await assert.rejects(
      run(new FakeDb(), employee, "PreviewLeaveRequest", { id: "r1" }),
      isCode("permission-denied"),
    );
  });
});

describe("leave requests use organization leave types", () => {
  const submitDb = () =>
    new FakeDb()
      .when("from branch where id", [{ id: "b1", name: "Main" }])
      .when("from organization_member where auth_uid", [{ id: "mem1", fullName: "Eve" }])
      .when("insert into leave_request", [{ id: "lr1" }])
      .when("from leave_request r join branch", [{ id: "lr1", status: "pending" }]);
  const vars = { branchId: "b1", startDate: "2026-01-05", endDate: "2026-01-06", reason: "Trip" };

  it("stores the chosen type of the caller's organization", async () => {
    const db = submitDb().when("from leave_type", [{ id: "t-annual" }]);
    await run(db, employee, "SubmitLeaveRequest", { ...vars, leaveTypeId: "t-annual" });
    const lookup = db.calls.find((c) => /from leave_type\b/i.test(c.sql))!;
    assert.deepEqual(lookup.params, ["t-annual", "o1"]);
    const insert = db.calls.find((c) => /insert into leave_request/i.test(c.sql))!;
    assert.match(insert.sql, /leave_type_id/);
    assert.doesNotMatch(insert.sql, /leave_type,/);
    assert.ok(insert.params.includes("t-annual"));
  });

  it("requires a leave type id (no fixed type codes)", async () => {
    await assert.rejects(
      run(submitDb(), employee, "SubmitLeaveRequest", { ...vars, leaveType: "sick" }),
      (e: { code?: string }) => e.code === "invalid-argument",
    );
  });

  it("refuses an archived or unknown type before writing", async () => {
    const db = submitDb();
    await assert.rejects(
      run(db, employee, "SubmitLeaveRequest", { ...vars, leaveTypeId: "gone" }),
      /available leave type/,
    );
    assert.ok(!db.calls.some((c) => /insert into leave_request/i.test(c.sql)));
  });
});
