import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { Actor } from "../auth/roles";
import { setSignInLookupForTests } from "../accounts/signInTimes";
import { runOperation } from "../data/dispatch";
import { operations } from "../data/registry";
import { FakeDb } from "./fakeDb";

const platform: Actor = { uid: "p1", role: "platformAdmin", branchIds: [] };
const orgAdmin: Actor = { uid: "a1", role: "orgAdmin", organizationId: "o1", branchIds: [] };
const manager: Actor = {
  uid: "m1",
  role: "branchManager",
  organizationId: "o1",
  branchIds: ["b1"],
};
const employee: Actor = { uid: "e1", role: "employee", organizationId: "o1", branchIds: ["b1"] };

function run(
  db: FakeDb,
  actor: Actor,
  op: string,
  vars: Record<string, unknown> = {},
  requireAcknowledgement = false,
) {
  return runOperation(
    operations,
    {
      db,
      actor,
      requireEmployeeAssetAcknowledgement: async () => requireAcknowledgement,
    },
    { op, vars },
  );
}

const denies = (p: Promise<unknown>) =>
  assert.rejects(p, (e: { code?: string }) => e.code === "permission-denied");

describe("GetPlatformStats", () => {
  it("counts Platform Administrators only, never the Platform Owner", async () => {
    const db = new FakeDb().when("organization_member", [{ _count: 2 }]);
    const res = (await run(db, platform, "GetPlatformStats")) as { platformAdminCount: unknown };
    const memberQuery = db.calls.find((c) => c.sql.includes("organization_member"));
    assert.ok(memberQuery, "expected a count over organization_member");
    assert.match(memberQuery.sql, /role = 'platformAdmin'/);
    assert.doesNotMatch(memberQuery.sql, /platformOwner/);
    assert.deepEqual(res.platformAdminCount, [{ _count: 2 }]);
  });
});

describe("dispatch", () => {
  it("rejects unknown and malformed operations", async () => {
    const db = new FakeDb();
    await assert.rejects(run(db, platform, "NoSuchOp"), (e: { code?: string }) => e.code === "invalid-argument");
    await assert.rejects(run(db, platform, "toString"), (e: { code?: string }) => e.code === "invalid-argument");
    assert.equal(db.calls.length, 0);
  });

  it("registers every client-facing connector operation", () => {
    const expected = [
      "ListOrganizations", "ListOrganizationsPaged", "GetOrganizationById", "GetOrganizationStats",
      "GetPlatformStats", "ListBranchesByOrg", "GetBranchById", "ListMyBranchAssignments",
      "GetMyMember", "ListMembersByOrg", "ListMembersByOrgPaged", "ListMembersByBranchPaged",
      "GetMemberById", "ListReturnsByBranch", "ListReturnsByBranchPaged", "ListReturnsByOrgPaged",
      "ListMyReturns", "GetReturnStatusCounts", "GetReturnById", "GetLeaveStatusCounts",
      "ListLeaveTypes", "GetLeavePolicy", "SaveLeaveType", "ArchiveLeaveType", "SetLeaveAccrual",
      "PreviewLeaveRequest",
      "GetOrganizationDashboardCounts", "GetReturnCountsByBranch", "GetBranchStats",
      "ListPlatformMembersPaged", "CreateOrganization", "UpdateOrganization",
      "CreateReturnRecord", "SubmitReturn", "SubmitReturnBatch", "ListLicensePlans", "CreateLicensePlan",
      "UpdateLicensePlan", "ChangeLicensePlanStatus", "DeleteLicensePlan", "GetOrganizationLicense",
      "GetOrganizationLicenseHistory", "AssignOrganizationLicense", "ChangeOrganizationLicensePlan",
      "ModifyOrganizationCommercialTerms", "RenewOrganizationLicense",
      "UpdateReturnRecordReview", "UpdateReturnRecordStatus",
      "ListMyEmployeeAssets", "ListOrganizationEmployeeAssets", "ListBranchEmployeeAssets",
      "SaveEmployeeAsset", "AcknowledgeMyEmployeeAsset", "DeleteEmployeeAsset",
    ];
    for (const name of expected) assert.ok(operations[name], name);
  });
});

describe("employee asset acknowledgments", () => {
  const assetRow = (acknowledgementStatus: string, acknowledgementRequired: boolean) => ({
    id: "asset-1",
    organizationId: "o1",
    branchId: "b1",
    branchName: "Main",
    employeeId: "member-e1",
    employeeName: "Employee One",
    name: "Work phone",
    category: "Device",
    assetTag: "WA-001",
    serialNumber: null,
    status: "assigned",
    notes: null,
    acknowledgementRequired,
    acknowledgementStatus,
    assignedByUid: "manager-1",
    assignedByName: "Organization Owner",
    assignedAt: "2026-11-02T08:30:00.000Z",
    acknowledgedByUid: acknowledgementStatus === "acknowledged" ? "e1" : null,
    acknowledgedByName: acknowledgementStatus === "acknowledged" ? "Employee One" : null,
    acknowledgedAt: acknowledgementStatus === "acknowledged" ? "2026-11-02T09:00:00.000Z" : null,
  });

  function saveDb(
    initialStatus = "assigned",
    insertError?: Error,
    { memberStatus = "active", existing }: {
      memberStatus?: string;
      existing?: { employeeId: string; status: string };
    } = {},
  ) {
    return new FakeDb().whenCall(({ sql }) => {
      const query = sql.toLowerCase();
      if (insertError && query.includes("insert into employee_asset")) throw insertError;
      if (existing && query.includes("from employee_asset") && query.includes("for update")) {
        return [{ id: "asset-1", organizationId: "o1", branchId: "b1", ...existing }];
      }
      if (query.includes("from branch where id = $1")) {
        return [{ id: "b1", organizationId: "o1" }];
      }
      if (query.includes("select full_name as \"fullname\"")) {
        return [{ fullName: "Organization Owner" }];
      }
      if (query.includes("from organization_member m") && query.includes("user_branch_assignment")) {
        return [{ id: "member-e1", role: "employee", status: memberStatus }];
      }
      if (query.includes("lower(asset_tag)")) return [];
      if (query.includes("insert into employee_asset")) return [{ id: "asset-1" }];
      if (query.includes("from employee_asset ea") && query.includes("join branch b")) {
        return [assetRow("pending", initialStatus === "assigned")];
      }
      return undefined;
    });
  }

  it("creates a pending receipt when the organization's policy is enabled", async () => {
    const db = saveDb();
    await run(db, orgAdmin, "SaveEmployeeAsset", {
      branchId: "b1",
      employeeId: "member-e1",
      name: "Work phone",
      category: "Device",
      assetTag: "WA-001",
      status: "assigned",
    }, true);
    const insert = db.calls.find((call) => call.sql.includes("INSERT INTO employee_asset"));
    assert.ok(insert);
    assert.equal(insert.params[9], true);
    assert.equal(insert.params[10], "pending");
    assert.equal(insert.params[11], orgAdmin.uid);
    assert.equal(insert.params[12], "Organization Owner");
    assert.match(insert.sql, /assigned_at\s*\)\s*VALUES[\s\S]*now\(\)/i);
  });

  it("reports a concurrent duplicate asset tag as a conflict, not an internal error", async () => {
    // Both saves passed the duplicate check; the unique index rejects this one.
    const uniqueViolation = Object.assign(
      new Error("duplicate key value violates unique constraint"),
      { code: "23505" },
    );
    await assert.rejects(
      run(saveDb("assigned", uniqueViolation), orgAdmin, "SaveEmployeeAsset", {
        branchId: "b1",
        employeeId: "member-e1",
        name: "Work phone",
        category: "Device",
        assetTag: "WA-001",
        status: "assigned",
      }),
      (e: { code?: string; message?: string }) =>
        e.code === "already-exists" && e.message === "That asset tag is already in use.",
    );
  });

  it("ignores client-supplied acknowledgment fields", async () => {
    const db = saveDb();
    await run(db, orgAdmin, "SaveEmployeeAsset", {
      branchId: "b1",
      employeeId: "member-e1",
      name: "Work phone",
      category: "Device",
      assetTag: "WA-001",
      status: "assigned",
      acknowledgementRequired: false,
      acknowledgementStatus: "acknowledged",
    }, true);
    const insert = db.calls.find((call) => call.sql.includes("INSERT INTO employee_asset"));
    assert.ok(insert);
    assert.equal(insert.params[9], true);
    assert.equal(insert.params[10], "pending");
  });

  it("creates a direct assignment when the policy is disabled", async () => {
    const db = saveDb();
    await run(db, orgAdmin, "SaveEmployeeAsset", {
      branchId: "b1",
      employeeId: "member-e1",
      name: "Work phone",
      category: "Device",
      assetTag: "WA-001",
      status: "assigned",
    });
    const insert = db.calls.find((call) => call.sql.includes("INSERT INTO employee_asset"));
    assert.ok(insert);
    assert.equal(insert.params[9], false);
    assert.equal(insert.params[10], "not_required");
  });

  it("does not request acknowledgment for an asset already marked returned", async () => {
    const db = saveDb("returned");
    await run(db, orgAdmin, "SaveEmployeeAsset", {
      branchId: "b1",
      employeeId: "member-e1",
      name: "Work phone",
      category: "Device",
      assetTag: "WA-001",
      status: "returned",
    }, true);
    const insert = db.calls.find((call) => call.sql.includes("INSERT INTO employee_asset"));
    assert.ok(insert);
    assert.equal(insert.params[9], false);
    assert.equal(insert.params[10], "not_required");
  });

  const assetVars = {
    branchId: "b1",
    employeeId: "member-e1",
    name: "Work phone",
    category: "Device",
    assetTag: "WA-001",
    status: "assigned",
  };
  const rejectsInactive = (e: { code?: string }) => e.code === "failed-precondition";

  it("does not hand a new asset to a suspended member", async () => {
    const db = saveDb("assigned", undefined, { memberStatus: "suspended" });
    await assert.rejects(run(db, orgAdmin, "SaveEmployeeAsset", assetVars), rejectsInactive);
    assert.ok(!db.calls.some((call) => /insert into employee_asset/i.test(call.sql)));
  });

  it("does not reassign or re-issue an asset to a suspended member", async () => {
    const transfer = saveDb("assigned", undefined, {
      memberStatus: "suspended",
      existing: { employeeId: "member-e9", status: "assigned" },
    });
    await assert.rejects(
      run(transfer, orgAdmin, "SaveEmployeeAsset", { ...assetVars, id: "asset-1" }),
      rejectsInactive,
    );
    const reissue = saveDb("assigned", undefined, {
      memberStatus: "suspended",
      existing: { employeeId: "member-e1", status: "returned" },
    });
    await assert.rejects(
      run(reissue, orgAdmin, "SaveEmployeeAsset", { ...assetVars, id: "asset-1" }),
      rejectsInactive,
    );
    for (const db of [transfer, reissue]) {
      assert.ok(!db.calls.some((call) => /update employee_asset/i.test(call.sql)));
    }
  });

  it("still lets managers edit or take back an asset a suspended member holds", async () => {
    for (const status of ["maintenance", "returned"]) {
      const db = saveDb("assigned", undefined, {
        memberStatus: "suspended",
        existing: { employeeId: "member-e1", status: "assigned" },
      });
      await run(db, orgAdmin, "SaveEmployeeAsset", { ...assetVars, id: "asset-1", status });
      assert.ok(db.calls.some((call) => /update employee_asset/i.test(call.sql)), status);
    }
  });

  it("starts a new acknowledgment when an asset is transferred", async () => {
    const db = new FakeDb().whenCall(({ sql }) => {
      const query = sql.toLowerCase();
      if (query.includes("from branch where id = $1")) {
        return [{ id: "b1", organizationId: "o1" }];
      }
      if (query.includes("from organization_member m") && query.includes("user_branch_assignment")) {
        return [{ id: "member-e2", role: "employee", status: "active" }];
      }
      if (query.includes("lower(asset_tag)")) return [];
      if (query.includes("from employee_asset") && query.includes("for update")) {
        return [{
          id: "asset-1",
          organizationId: "o1",
          branchId: "b1",
          employeeId: "member-e1",
          status: "assigned",
        }];
      }
      if (query.includes("from employee_asset ea") && query.includes("join branch b")) {
        return [assetRow("pending", true)];
      }
      if (query.includes("select full_name as \"fullname\"")) {
        return [{ fullName: "Organization Owner" }];
      }
      return undefined;
    });
    await run(db, orgAdmin, "SaveEmployeeAsset", {
      id: "asset-1",
      branchId: "b1",
      employeeId: "member-e2",
      name: "Work phone",
      category: "Device",
      assetTag: "WA-001",
      status: "assigned",
    }, true);
    const update = db.calls.find((call) => call.sql.includes("UPDATE employee_asset"));
    assert.ok(update);
    assert.equal(update.params[9], true);
    assert.equal(update.params[10], true);
    assert.equal(update.params[11], "pending");
  });

  it("allows only the assigned employee to acknowledge and records their uid", async () => {
    const db = new FakeDb().whenCall(({ sql }) => {
      const query = sql.toLowerCase();
      if (query.includes("for update of ea")) {
        return [{ id: "asset-1", acknowledgementRequired: true, acknowledgementStatus: "pending", employeeName: "Employee One" }];
      }
      if (query.includes("update employee_asset")) return [];
      if (query.includes("from employee_asset ea") && query.includes("join branch b")) {
        return [assetRow("acknowledged", true)];
      }
      return undefined;
    });
    const result = await run(db, employee, "AcknowledgeMyEmployeeAsset", { assetId: "asset-1" });
    const update = db.calls.find((call) => call.sql.includes("UPDATE employee_asset"));
    assert.ok(update);
    assert.equal(update.params[1], employee.uid);
    assert.equal(update.params[2], "Employee One");
    assert.deepEqual((result as { employeeAsset: { acknowledgementStatus: string } }).employeeAsset.acknowledgementStatus, "acknowledged");
    const lookup = db.calls.find((call) => call.sql.includes("FOR UPDATE OF ea"));
    assert.ok(lookup);
    assert.match(lookup.sql, /m\.auth_uid = \$3/);
    assert.deepEqual(lookup.params, ["asset-1", "o1", "e1"]);
  });

  it("does not let an employee acknowledge another employee's asset", async () => {
    const db = new FakeDb().whenCall(({ sql }) =>
      sql.toLowerCase().includes("for update of ea") ? [] : undefined,
    );
    await denies(run(db, employee, "AcknowledgeMyEmployeeAsset", { assetId: "asset-2" }));
    assert.equal(db.calls.some((call) => call.sql.includes("UPDATE employee_asset")), false);
  });

  it("denies managers from acknowledging for employees", async () => {
    const db = new FakeDb();
    await denies(run(db, manager, "AcknowledgeMyEmployeeAsset", { assetId: "asset-1" }));
    assert.equal(db.calls.length, 0);
  });
});

describe("organizations ops", () => {
  it("denies non-platform callers", async () => {
    await denies(run(new FakeDb(), orgAdmin, "ListOrganizationsPaged", { limit: 10, offset: 0 }));
    await denies(run(new FakeDb(), employee, "GetOrganizationById", { id: "o2" }));
    await denies(run(new FakeDb(), platform, "UpdateOrganization", { id: "o1", status: "suspended" }));
  });

  it("pages with escaped case-insensitive filter and returns total", async () => {
    const db = new FakeDb()
      .when("count(*)", [{ _count: 7 }])
      .when("from organization", [{ id: "o1", name: "Acme" }]);
    const res = (await run(db, platform, "ListOrganizationsPaged", {
      limit: 5,
      offset: 10,
      nameContains: "50%_off",
    })) as { organizations: unknown[]; total: unknown };
    assert.deepEqual(res.total, [{ _count: 7 }]);
    assert.equal(res.organizations.length, 1);
    const list = db.calls[1];
    assert.match(list.sql, /\(name ILIKE \$1 OR code ILIKE \$1\)/);
    assert.match(list.sql, /AS "branchCount"/);
    assert.match(list.sql, /AS "memberCount"/);
    assert.deepEqual(list.params, ["%50\\%\\_off%", 5, 10]);
  });

  it("platform administrator rows carry the last sign-in time from Auth", async () => {
    setSignInLookupForTests(async (uids) => new Map(uids.map((uid) => [uid, "2026-11-15T10:00:00.000Z"])));
    try {
      const db = new FakeDb()
        .when("count(*)", [{ _count: 1 }])
        .when("from organization_member m", [
          { id: "m1", authUid: "u1", role: "platformAdmin", fullName: "Admin" },
        ]);
      const res = (await run(db, platform, "ListPlatformMembersPaged", { limit: 5, offset: 0 })) as {
        organizationMembers: { lastSignInAt: string | null }[];
      };
      assert.equal(res.organizationMembers[0].lastSignInAt, "2026-11-15T10:00:00.000Z");
    } finally {
      setSignInLookupForTests(undefined);
    }
  });

  it("creates an organization with defaults and maps duplicate codes", async () => {
    const db = new FakeDb().when("insert into organization", [{ id: "new" }]);
    const res = await run(db, platform, "CreateOrganization", { name: "N", code: "C" });
    assert.deepEqual(res, { organization_insert: { id: "new" } });
    assert.ok(db.calls[0].params.includes("INR") && db.calls[0].params.includes("active"));

    const dup = new FakeDb().whenCall(() => {
      throw Object.assign(new Error("dup"), { code: "23505" });
    });
    await assert.rejects(
      run(dup, platform, "CreateOrganization", { name: "N", code: "C" }),
      (e: { code?: string }) => e.code === "already-exists",
    );
  });
});

describe("branches ops", () => {
  it("scopes GetBranchById by role", async () => {
    const branch = { id: "b2", name: "B", organizationId: "o1" };
    const db = () => new FakeDb().when("from branch b where", [branch]);
    await denies(run(db(), manager, "GetBranchById", { id: "b2" }));
    await denies(run(db(), { ...orgAdmin, organizationId: "o9" }, "GetBranchById", { id: "b2" }));
    const res = await run(db(), orgAdmin, "GetBranchById", { id: "b2" });
    assert.deepEqual(res, { branch: { id: "b2", name: "B", organization: { id: "o1" } } });
  });

  it("nests the branch in the caller's assignments", async () => {
    const db = new FakeDb().when("user_branch_assignment", [
      { assignmentId: "a1", id: "b1", name: "B", organizationId: "o1" },
    ]);
    const res = await run(db, employee, "ListMyBranchAssignments");
    assert.deepEqual(res, {
      userBranchAssignments: [{ id: "a1", branch: { id: "b1", name: "B", organization: { id: "o1" } } }],
    });
    assert.deepEqual(db.calls[0].params, ["e1"]);
  });
});

describe("members ops", () => {
  it("denies member reads outside the caller's scope", async () => {
    await denies(run(new FakeDb(), orgAdmin, "ListMembersByOrg", { orgId: "o2" }));
    await denies(run(new FakeDb(), employee, "ListMembersByOrgPaged", { orgId: "o1", limit: 1, offset: 0 }));
    const db = new FakeDb().when("from organization_member m where", [
      { id: "m9", authUid: "other", organizationId: "o1", role: "employee" },
    ]);
    await denies(run(db, employee, "GetMemberById", { id: "m9" }));
  });

  it("lets a Branch Manager read employees, not peer managers, in their branches", async () => {
    const db = (role: string) =>
      new FakeDb()
        .when("from organization_member m where", [
          { id: "m9", authUid: "other", organizationId: "o1", role },
        ])
        .when("a.member_id in", [{ memberId: "m9", branchId: "b1", branchName: "B" }]);
    await denies(run(db("branchManager"), manager, "GetMemberById", { id: "m9" }));
    await denies(run(db("orgAdmin"), manager, "GetMemberById", { id: "m9" }));
  });

  it("limits branch member lists to managed branches and nests members", async () => {
    await denies(run(new FakeDb(), manager, "ListMembersByBranchPaged", { branchId: "b2", limit: 1, offset: 0 }));
    const db = new FakeDb()
      .when("select id, organization_id", [{ id: "b1", organizationId: "o1" }])
      .when("count(*)", [{ _count: 1 }])
      .when("from user_branch_assignment a join organization_member", [{ id: "m2", fullName: "Zed" }])
      .when("a.member_id in", [{ memberId: "m2", branchId: "b1", branchName: "B" }]);
    const res = (await run(db, manager, "ListMembersByBranchPaged", { branchId: "b1", limit: 10, offset: 0 })) as {
      userBranchAssignments: { member: Record<string, unknown> }[];
      total: unknown;
    };
    assert.deepEqual(res.total, [{ _count: 1 }]);
    assert.deepEqual(res.userBranchAssignments[0].member.userBranchAssignments_on_member, [
      { branch: { id: "b1", name: "B" } },
    ]);
  });

  it("lets a member read themselves and returns the nested organization", async () => {
    const db = new FakeDb()
      .when("from organization_member m where", [{ id: "m1", authUid: "e1", organizationId: "o1" }])
      .when("a.member_id in", [{ memberId: "m1", branchId: "b1", branchName: "B" }]);
    const res = (await run(db, employee, "GetMemberById", { id: "m1" })) as {
      organizationMember: Record<string, unknown>;
    };
    assert.deepEqual(res.organizationMember.organization, { id: "o1" });
    assert.deepEqual(res.organizationMember.userBranchAssignments_on_member, [
      { branch: { id: "b1", name: "B" } },
    ]);
  });
});

describe("returns ops", () => {
  it("only lets employees/managers submit into their own branches", async () => {
    const vars = { branchId: "b1", productTitle: "P", returnReason: "R", quantity: 2, unit: "pc", invoiceNumber: "I" };
    await denies(run(new FakeDb(), orgAdmin, "SubmitReturn", vars));
    await denies(run(new FakeDb(), employee, "SubmitReturn", { ...vars, branchId: "b2" }));
    await assert.rejects(
      run(new FakeDb(), employee, "SubmitReturn", { ...vars, quantity: 0 }),
      (e: { code?: string }) => e.code === "invalid-argument",
    );
  });

  it("stamps org, submitter and uid on SubmitReturn", async () => {
    const db = new FakeDb()
      .when("from organization_member where auth_uid", [{ id: "mem1", authUid: "e1", fullName: "Eve" }])
      .when("from branch where id", [{ status: "active", organizationId: "o1" }])
      .when("insert into return_record", [{ id: "r1" }]);
    const res = await run(db, employee, "SubmitReturn", {
      branchId: "b1", productTitle: "Shoe", returnReason: "Torn", quantity: 2, unit: "pc", invoiceNumber: "INV1",
    });
    assert.deepEqual(res, { returnRecord_insert: { id: "r1" } });
    assert.equal(db.transactions, 1);
    const insert = db.calls.find((c) => /insert into return_record/i.test(c.sql))!;
    for (const v of ["o1", "b1", "mem1", "e1", "Eve", "Shoe", 2, "pc", "INV1", "pending"]) {
      assert.ok(insert.params.includes(v), String(v));
    }
  });

  it("stores the bill number and business return date", async () => {
    const db = new FakeDb()
      .when("from organization_member where auth_uid", [{ id: "mem1", authUid: "e1", fullName: "Eve" }])
      .when("from branch where id", [{ status: "active", organizationId: "o1" }])
      .when("insert into return_record", [{ id: "r1" }]);
    await run(db, employee, "SubmitReturn", {
      branchId: "b1", productTitle: "Shoe", returnReason: "Torn", quantity: 2, unit: "pc",
      invoiceNumber: "INV1", billNumber: "BILL-7", returnDate: "2024-03-05",
    });
    const insert = db.calls.find((c) => /insert into return_record/i.test(c.sql))!;
    assert.match(insert.sql, /bill_number/);
    assert.match(insert.sql, /return_date/);
    assert.ok(insert.params.includes("BILL-7"));
    assert.ok(insert.params.includes("2024-03-05"));
  });

  it("rejects a return dated after the business day", async () => {
    await assert.rejects(
      run(new FakeDb(), employee, "SubmitReturn", {
        branchId: "b1", productTitle: "Shoe", returnReason: "Torn", quantity: 2, unit: "pc",
        invoiceNumber: "INV1", returnDate: "2999-01-01",
      }),
      (e: { code?: string }) => e.code === "invalid-argument",
    );
  });

  it("submits every line of a bill in one transaction", async () => {
    let next = 0;
    const db = new FakeDb()
      .when("from organization_member where auth_uid", [{ id: "mem1", authUid: "e1", fullName: "Eve" }])
      .when("from branch where id", [{ status: "active", organizationId: "o1" }])
      .whenCall((c) => (/insert into return_record/i.test(c.sql) ? [{ id: `r${++next}` }] : undefined));
    const res = await run(db, employee, "SubmitReturnBatch", {
      branchId: "b1", invoiceNumber: "INV1", billNumber: "BILL-7",
      items: [
        { productTitle: "Shoe", quantity: 2, unit: "pc", returnReason: "damaged" },
        { productTitle: "Sock", quantity: 1, unit: "pc", returnReason: "expired", remarks: "Torn" },
      ],
    });
    assert.deepEqual(res, { returnRecord_inserts: [{ id: "r1" }, { id: "r2" }] });
    assert.equal(db.transactions, 1);
    const inserts = db.calls.filter((c) => /insert into return_record/i.test(c.sql));
    assert.equal(inserts.length, 2);
    for (const insert of inserts) assert.ok(insert.params.includes("BILL-7"));
  });

  it("fails the whole batch when one line cannot be saved", async () => {
    let inserts = 0;
    const db = new FakeDb()
      .when("from organization_member where auth_uid", [{ id: "mem1", authUid: "e1", fullName: "Eve" }])
      .when("from branch where id", [{ status: "active", organizationId: "o1" }])
      .whenCall((c) => {
        if (!/insert into return_record/i.test(c.sql)) return undefined;
        inserts += 1;
        if (inserts === 2) throw new Error("connection reset");
        return [{ id: "r1" }];
      });
    await assert.rejects(
      run(db, employee, "SubmitReturnBatch", {
        branchId: "b1", invoiceNumber: "INV1",
        items: [
          { productTitle: "Shoe", quantity: 2, unit: "pc", returnReason: "damaged" },
          { productTitle: "Sock", quantity: 1, unit: "pc", returnReason: "expired" },
        ],
      }),
    );
    assert.equal(db.transactions, 1);
  });

  it("validates every batch line before writing", async () => {
    const vars = { branchId: "b1", invoiceNumber: "INV1" };
    const isInvalid = (e: { code?: string }) => e.code === "invalid-argument";
    await assert.rejects(run(new FakeDb(), employee, "SubmitReturnBatch", { ...vars, items: [] }), isInvalid);
    const db = new FakeDb();
    await assert.rejects(
      run(db, employee, "SubmitReturnBatch", {
        ...vars,
        items: [
          { productTitle: "Shoe", quantity: 2, unit: "pc", returnReason: "damaged" },
          { productTitle: "Sock", quantity: 0, unit: "pc", returnReason: "expired" },
        ],
      }),
      isInvalid,
    );
    assert.equal(db.calls.length, 0);
    await denies(run(new FakeDb(), employee, "SubmitReturnBatch", {
      ...vars, branchId: "b2", items: [{ productTitle: "Shoe", quantity: 2, unit: "pc", returnReason: "damaged" }],
    }));
  });

  it("rejects a review of an already-reviewed or out-of-scope return", async () => {
    const reviewer = new FakeDb().when("from organization_member where auth_uid", [{ id: "mem", fullName: "Mo" }]);
    reviewer.when("from return_record where id", [
      { status: "approved", organizationId: "o1", branchId: "b1" },
    ]);
    await denies(run(reviewer, manager, "UpdateReturnRecordReview", { id: "r1", status: "approved" }));

    const other = new FakeDb().when("from organization_member where auth_uid", [{ id: "mem", fullName: "Mo" }]);
    other.when("from return_record where id", [{ status: "pending", organizationId: "o1", branchId: "b2" }]);
    await denies(run(other, manager, "UpdateReturnRecordReview", { id: "r1", status: "approved" }));
    await denies(run(new FakeDb(), employee, "UpdateReturnRecordReview", { id: "r1", status: "approved" }));
  });

  it("stamps reviewer identity on approval", async () => {
    const db = new FakeDb()
      .when("from organization_member where auth_uid", [{ id: "mem", fullName: "Mo" }])
      .when("from return_record where id", [{ status: "pending", organizationId: "o1", branchId: "b1" }])
      .when("update return_record", [{ id: "r1" }]);
    const res = await run(db, manager, "UpdateReturnRecordReview", {
      id: "r1", status: "rejected", reviewerNotes: "no bill",
    });
    assert.deepEqual(res, { returnRecord_update: { id: "r1" } });
    assert.deepEqual(db.calls.at(-1)!.params, ["r1", "rejected", "no bill", "m1", "Mo"]);
  });

  it("returns org lists with nested branch and total", async () => {
    await denies(run(new FakeDb(), manager, "ListReturnsByOrgPaged", { orgId: "o1", limit: 1, offset: 0 }));
    const db = new FakeDb()
      .when("count(*)", [{ _count: 3 }])
      .when("join branch b", [{ id: "r1", branchRefId: "b1", branchRefName: "B" }]);
    const res = (await run(db, orgAdmin, "ListReturnsByOrgPaged", {
      orgId: "o1", limit: 5, offset: 0, status: "pending", branchId: "b1",
    })) as { returnRecords: unknown[]; total: unknown };
    assert.deepEqual(res.returnRecords, [{ id: "r1", branch: { id: "b1", name: "B" } }]);
    assert.deepEqual(res.total, [{ _count: 3 }]);
    assert.deepEqual(db.calls[1].params, ["o1", "b1", "pending", 5, 0]);
  });
});

describe("dashboards ops", () => {
  it("denies foreign organizations and branches", async () => {
    await denies(run(new FakeDb(), orgAdmin, "GetOrganizationDashboardCounts", { orgId: "o2" }));
    await denies(run(new FakeDb(), manager, "GetBranchStats", { branchId: "b2" }));
  });

  it("returns group rows with numeric counts and period filters", async () => {
    const db = new FakeDb().when("group by branch_id, status", [{ branchId: "b1", status: "pending", _count: "4" }]);
    const res = (await run(db, orgAdmin, "GetReturnCountsByBranch", {
      orgId: "o1", from: "2026-01-01T00:00:00Z", to: "2026-02-01T00:00:00Z",
    })) as { returnRecords: unknown[] };
    assert.deepEqual(res.returnRecords, [{ branchId: "b1", status: "pending", _count: 4 }]);
    assert.deepEqual(db.calls[0].params, ["o1", "2026-01-01T00:00:00.000Z", "2026-02-01T00:00:00.000Z"]);
  });
});
