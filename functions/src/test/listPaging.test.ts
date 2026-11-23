import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { Actor } from "../auth/roles";
import { runOperation } from "../data/dispatch";
import { operations } from "../data/registry";
import { FakeDb, type RecordedCall } from "./fakeDb";

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

const pageQuery = (db: FakeDb): RecordedCall =>
  db.calls.find((c) => /\bLIMIT \$\d+ OFFSET \$\d+/.test(c.sql))!;
const countQuery = (db: FakeDb): RecordedCall =>
  db.calls.find((c) => /count\(\*\)::int AS "_count"/.test(c.sql))!;

const branchDb = () =>
  new FakeDb()
    .when("from branch where id", [{ id: "b1", organizationId: "o1" }])
    .when('count(*)::int as "_count"', [{ _count: 3 }]);

describe("returns paging", () => {
  it("searches product, bill, invoice, submitter and branch with escaped text", async () => {
    const db = branchDb();
    const res = (await run(db, orgAdmin, "ListReturnsByOrgPaged", {
      orgId: "o1", limit: 20, offset: 40, query: "50%_off",
    })) as { total: { _count: number }[] };
    assert.deepEqual(res.total, [{ _count: 3 }]);
    const page = pageQuery(db);
    for (const column of ["r.product_title", "r.invoice_number", "r.bill_number", "r.employee_name", "b.name"]) {
      assert.match(page.sql, new RegExp(`${column.replace(".", "\\.")} ILIKE`));
    }
    assert.ok(page.params.includes("%50\\%\\_off%"));
    assert.deepEqual(page.params.slice(-2), [20, 40]);
    assert.match(page.sql, /ORDER BY COALESCE\(r\.return_date/);
  });

  it("splits a branch queue into the manager's own and others' returns", async () => {
    const mine = branchDb();
    await run(mine, manager, "ListReturnsByBranchPaged", {
      branchId: "b1", submitter: "mine", limit: 20, offset: 0,
    });
    assert.match(countQuery(mine).sql, /\(r\.employee_uid = \$2 OR \(r\.employee_uid IS NULL AND r\.employee_id = \$2\)\)/);
    const others = branchDb();
    await run(others, manager, "ListReturnsByBranchPaged", {
      branchId: "b1", submitter: "others", limit: 20, offset: 0,
    });
    assert.match(countQuery(others).sql, /NOT \(r\.employee_uid = \$2/);
    assert.deepEqual(countQuery(others).params.slice(0, 2), ["b1", "m1"]);
  });

  it("counts returns per status for a scope, ignoring status and search", async () => {
    const db = new FakeDb().when("group by r.status", [
      { status: "pending", count: 2 },
      { status: "approved", count: 5 },
    ]);
    const res = await run(db, employee, "GetReturnStatusCounts", {
      scope: "mine", status: "approved", query: "milk",
    });
    assert.deepEqual(res, { counts: { pending: 2, approved: 5, rejected: 0 } });
    const query = db.calls.at(-1)!;
    assert.doesNotMatch(query.sql, /ILIKE|r\.status =/);
    assert.deepEqual(query.params, ["e1"]);
  });

  it("refuses counts outside the caller's scope", async () => {
    await assert.rejects(
      run(new FakeDb(), employee, "GetReturnStatusCounts", { scope: "organization", orgId: "o1" }),
      (e: { code?: string }) => e.code === "permission-denied",
    );
    await assert.rejects(
      run(new FakeDb(), manager, "GetReturnStatusCounts", { scope: "branch", branchId: "b9" }),
      (e: { code?: string }) => e.code === "permission-denied",
    );
  });

  it("opens a single return only for its submitter or someone who manages it", async () => {
    const row = {
      id: "r1", employeeId: "mem9", employeeUid: "e9", organizationId: "o1",
      branchRefId: "b1", branchRefName: "Main", status: "pending",
    };
    const db = () => new FakeDb().when("from return_record r join branch b", [row]);
    const ownerView = await run(db(), { ...employee, uid: "e9" }, "GetReturnById", { id: "r1" });
    assert.deepEqual((ownerView as { returnRecord: { branch: unknown } }).returnRecord.branch, { id: "b1", name: "Main" });
    assert.ok(((await run(db(), manager, "GetReturnById", { id: "r1" })) as { returnRecord: unknown }).returnRecord);
    assert.ok(((await run(db(), orgAdmin, "GetReturnById", { id: "r1" })) as { returnRecord: unknown }).returnRecord);
    assert.deepEqual(await run(db(), employee, "GetReturnById", { id: "r1" }), { returnRecord: null });
    const otherManager: Actor = { ...manager, branchIds: ["b2"] };
    assert.deepEqual(await run(db(), otherManager, "GetReturnById", { id: "r1" }), { returnRecord: null });
    const otherOrgAdmin: Actor = { ...orgAdmin, organizationId: "o2" };
    assert.deepEqual(await run(db(), otherOrgAdmin, "GetReturnById", { id: "r1" }), { returnRecord: null });
  });
});

describe("leave paging", () => {
  it("orders pending requests first, then by start date", async () => {
    const db = new FakeDb().when('count(*)::int as "_count"', [{ _count: 0 }]);
    await run(db, employee, "ListMyLeaveRequests", { limit: 20, offset: 0 });
    assert.match(pageQuery(db).sql, /ORDER BY \(r\.status = 'pending'\) DESC, r\.start_date ASC/);
  });

  it("counts leave requests per status for a branch's employees", async () => {
    const db = new FakeDb()
      .when("from branch where id", [{ id: "b1", name: "Main" }])
      .when("group by r.status", [{ status: "pending", count: 4 }, { status: "rejected", count: 1 }]);
    const res = await run(db, manager, "GetLeaveStatusCounts", { scope: "branchEmployees", branchId: "b1" });
    assert.deepEqual(res, { counts: { pending: 4, approved: 0, rejected: 1 } });
    assert.match(db.calls.at(-1)!.sql, /r\.applicant_role = \$2/);
  });

  it("keeps each count scope to its role", async () => {
    const denied = (e: { code?: string }) => e.code === "permission-denied";
    await assert.rejects(run(new FakeDb(), employee, "GetLeaveStatusCounts", { scope: "organization" }), denied);
    await assert.rejects(run(new FakeDb(), orgAdmin, "GetLeaveStatusCounts", { scope: "mine" }), denied);
    await assert.rejects(
      run(new FakeDb(), manager, "GetLeaveStatusCounts", { scope: "branchEmployees", branchId: "b9" }),
      denied,
    );
  });
});

describe("asset paging", () => {
  it("pages and searches organization assets", async () => {
    const db = new FakeDb().when('count(*)::int as "_count"', [{ _count: 12 }]);
    const res = (await run(db, orgAdmin, "ListOrganizationEmployeeAssets", {
      limit: 10, offset: 10, query: "laptop",
    })) as { total: { _count: number }[] };
    assert.deepEqual(res.total, [{ _count: 12 }]);
    const page = pageQuery(db);
    assert.match(page.sql, /ea\.asset_tag ILIKE/);
    assert.deepEqual(page.params, ["o1", "%laptop%", 10, 10]);
  });

  it("caps a request without paging variables (older clients)", async () => {
    const db = new FakeDb();
    await run(db, orgAdmin, "ListOrganizationEmployeeAssets");
    assert.deepEqual(pageQuery(db).params.slice(-2), [500, 0]);
  });
});
