import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { Actor } from "../auth/roles";
import { runOperation } from "../data/dispatch";
import { operations } from "../data/registry";
import { generatePlanCode } from "../licenses/planCode";
import { FakeDb } from "./fakeDb";
import { LICENSE_LOCK, usableLicense } from "./licenseFixtures";

const platform: Actor = { uid: "p1", role: "platformOwner", branchIds: [] };
const orgAdmin: Actor = { uid: "a1", role: "orgAdmin", organizationId: "o1", branchIds: [] };
const manager: Actor = { uid: "m1", role: "branchManager", organizationId: "o1", branchIds: ["b1"] };
const employee: Actor = { uid: "e1", role: "employee", organizationId: "o1", branchIds: ["b1"] };

function run(db: FakeDb, actor: Actor, op: string, vars: Record<string, unknown> = {}) {
  return runOperation(
    operations,
    {
      db,
      actor,
      requireEmployeeAssetAcknowledgement: async () => false,
    },
    { op, vars },
  );
}

const denies = (p: Promise<unknown>) =>
  assert.rejects(p, (e: { code?: string }) => e.code === "permission-denied");

async function refused(p: Promise<unknown>, code: string, message?: string): Promise<void> {
  await assert.rejects(p, (e: { code?: string; message?: string }) => {
    assert.equal(e.code, code);
    if (message !== undefined) assert.equal(e.message, message);
    return true;
  });
}

const uniqueViolation = (constraint: string) =>
  Object.assign(new Error(`duplicate key value violates unique constraint "${constraint}"`), {
    code: "23505",
    constraint,
  });

const LICENSE_ROW = "from organization_license ol";
const PLAN_ROW = "from license_plan where id";
const ORG_ROW = "select id from organization where id";
const LICENSE_EXISTS = "from organization_license where organization_id";
const PLAN_LIST = "from license_plan p ";
const PLAN_SUMMARY_ROW = "as \"totalplans\"";

const ALL_PLATFORM_OPS = [
  "ListLicensePlans",
  "CreateLicensePlan",
  "UpdateLicensePlan",
  "ChangeLicensePlanStatus",
  "DeleteLicensePlan",
  "GetOrganizationLicense",
  "GetOrganizationLicenseHistory",
  "AssignOrganizationLicense",
  "ChangeOrganizationLicensePlan",
  "ModifyOrganizationCommercialTerms",
  "RenewOrganizationLicense",
];

describe("license operation registry", () => {
  it("registers the eleven plan and license operations and no commercial ones", () => {
    for (const name of ALL_PLATFORM_OPS) assert.ok(operations[name], name);
    for (const old of [
      "GetCommercialAgreementByOrg",
      "ListLicenseEventsByOrg",
      "CreateCommercialAgreement",
      "UpdateCommercialAgreement",
      "CreateLicenseEvent",
    ]) {
      assert.equal(operations[old], undefined, old);
    }
  });
});

describe("license operations authorization", () => {
  it("denies every license operation to organization and branch roles", async () => {
    for (const actor of [orgAdmin, manager, employee]) {
      for (const op of ALL_PLATFORM_OPS) {
        await denies(run(new FakeDb(), actor, op, { organizationId: "o1", id: "x" }));
      }
    }
  });
});

describe("generatePlanCode", () => {
  it("is PLN, twelve hex characters, then the name's letters and digits (max 10)", () => {
    assert.equal(generatePlanCode("Basic Plan", "a1b2c3d4e5f6"), "PLN-A1B2C3D4E5F6-BASICPLAN");
    assert.equal(
      generatePlanCode("Enterprise Pro Max Edition", "000000000001"),
      "PLN-000000000001-ENTERPRISE",
    );
  });

  it("falls back to PLAN when the name has no letters or digits", () => {
    assert.equal(generatePlanCode("--", "000000000002"), "PLN-000000000002-PLAN");
  });

  it("generates twelve random hex characters by default", () => {
    assert.match(generatePlanCode("Gold"), /^PLN-[0-9A-F]{12}-GOLD$/);
  });
});

describe("ListLicensePlans", () => {
  it("rejects an unknown status filter", async () => {
    await assert.rejects(run(new FakeDb(), platform, "ListLicensePlans", { status: "archived" }), {
      code: "invalid-argument",
    });
  });

  it("filters by status and an escaped name-or-code pattern, then reads the summary", async () => {
    const db = new FakeDb()
      .when(PLAN_LIST, [{ id: "plan-pro", name: "Pro", level: 3 }])
      .when(PLAN_SUMMARY_ROW, [
        { totalPlans: 5, activePlans: 4, inactivePlans: 1, assignedOrganizations: 2 },
      ]);
    const res = await run(db, platform, "ListLicensePlans", { status: "active", query: "50%" });
    assert.deepEqual(res, {
      licensePlans: [{ id: "plan-pro", name: "Pro", level: 3 }],
      summary: { totalPlans: 5, activePlans: 4, inactivePlans: 1, assignedOrganizations: 2 },
    });
    const list = db.calls[0];
    assert.match(list.sql, /WHERE p\.status = \$1/);
    assert.match(list.sql, /ORDER BY p\.level ASC/);
    assert.match(list.sql, /\(p\.name ILIKE \$2 OR p\.plan_code ILIKE \$2\)/);
    assert.deepEqual(list.params, ["active", "%50\\%%"]);
  });
});

describe("CreateLicensePlan", () => {
  const valid = {
    name: "  Basic Plan  ",
    level: 6,
    maxStores: 2,
    maxUsers: 20,
    status: "active",
  };

  it("denies non-platform callers", async () => {
    await denies(run(new FakeDb(), orgAdmin, "CreateLicensePlan", valid));
  });

  it("validates each field", async () => {
    const bad: Record<string, unknown>[] = [
      { ...valid, name: "A" },
      { ...valid, name: "x".repeat(61) },
      { ...valid, description: "d".repeat(201) },
      { ...valid, level: 0 },
      { ...valid, level: 1.5 },
      { ...valid, level: 1_000_001 },
      { ...valid, maxStores: 0 },
      { ...valid, maxUsers: 1_000_001 },
      { ...valid, status: "archived" },
      { ...valid, status: undefined },
    ];
    for (const vars of bad) {
      await assert.rejects(run(new FakeDb(), platform, "CreateLicensePlan", vars), {
        code: "invalid-argument",
      });
    }
  });

  it("inserts a trimmed plan with a generated code and an empty description by default", async () => {
    const db = new FakeDb().when("insert into license_plan", [{ id: "p9", planCode: "PLN-X" }]);
    const res = await run(db, platform, "CreateLicensePlan", valid);
    assert.deepEqual(res, { licensePlan_insert: { id: "p9", planCode: "PLN-X" } });
    const insert = db.calls[0];
    assert.match(insert.params[0] as string, /^PLN-[0-9A-F]{12}-BASICPLAN$/);
    assert.deepEqual(insert.params.slice(1), ["Basic Plan", "", 6, 2, 20, "active"]);
  });

  it("refuses a duplicate level and a duplicate name", async () => {
    await refused(
      run(
        new FakeDb().whenCall(() => {
          throw uniqueViolation("license_plan_level_key");
        }),
        platform,
        "CreateLicensePlan",
        valid,
      ),
      "already-exists",
      "A license plan with this level already exists.",
    );
    await refused(
      run(
        new FakeDb().whenCall(() => {
          throw uniqueViolation("license_plan_name_lower_key");
        }),
        platform,
        "CreateLicensePlan",
        valid,
      ),
      "already-exists",
      "A license plan with this name already exists.",
    );
  });

  it("retries a plan code collision and succeeds on a later attempt", async () => {
    let attempts = 0;
    const db = new FakeDb().whenCall((c) => {
      if (!c.sql.startsWith("INSERT INTO license_plan")) return undefined;
      attempts += 1;
      if (attempts < 3) throw uniqueViolation("license_plan_plan_code_key");
      return [{ id: "p9", planCode: "PLN-OK" }];
    });
    const res = await run(db, platform, "CreateLicensePlan", valid);
    assert.deepEqual(res, { licensePlan_insert: { id: "p9", planCode: "PLN-OK" } });
    assert.equal(attempts, 3);
  });

  it("gives up after five plan code collisions", async () => {
    const db = new FakeDb().whenCall(() => {
      throw uniqueViolation("license_plan_plan_code_key");
    });
    await refused(
      run(db, platform, "CreateLicensePlan", valid),
      "already-exists",
      "Could not generate a unique plan code. Try again.",
    );
    assert.equal(db.calls.length, 5);
  });
});

describe("UpdateLicensePlan", () => {
  const valid = { id: "p1", name: "Pro", level: 3, maxStores: 5, maxUsers: 75 };

  it("keeps the description when it is omitted and clears it when it is empty", async () => {
    const db = new FakeDb().when("update license_plan", [{ id: "p1" }]);
    await run(db, platform, "UpdateLicensePlan", valid);
    assert.equal(db.calls[0].params[2], null);
    await run(db, platform, "UpdateLicensePlan", { ...valid, description: "  " });
    assert.equal(db.calls[1].params[2], "");
  });

  it("returns null for a missing plan", async () => {
    assert.deepEqual(await run(new FakeDb(), platform, "UpdateLicensePlan", valid), {
      licensePlan_update: null,
    });
  });

  it("refuses a level or name already used by another plan", async () => {
    await refused(
      run(
        new FakeDb().whenCall(() => {
          throw uniqueViolation("license_plan_level_key");
        }),
        platform,
        "UpdateLicensePlan",
        valid,
      ),
      "already-exists",
      "A license plan with this level already exists.",
    );
  });

  it("validates the same fields as create", async () => {
    await assert.rejects(run(new FakeDb(), platform, "UpdateLicensePlan", { ...valid, maxUsers: 0 }), {
      code: "invalid-argument",
    });
  });
});

describe("ChangeLicensePlanStatus and DeleteLicensePlan", () => {
  it("changes status and returns null for a missing plan", async () => {
    const db = new FakeDb()
      .when("for update", [{ id: "p1" }])
      .when("set status", [{ id: "p1", status: "inactive" }]);
    assert.deepEqual(
      await run(db, platform, "ChangeLicensePlanStatus", { id: "p1", status: "inactive" }),
      { licensePlan_update: { id: "p1", status: "inactive" } },
    );
    assert.deepEqual(
      await run(new FakeDb(), platform, "ChangeLicensePlanStatus", { id: "p9", status: "active" }),
      { licensePlan_update: null },
    );
    await assert.rejects(
      run(new FakeDb(), platform, "ChangeLicensePlanStatus", { id: "p1", status: "gone" }),
      { code: "invalid-argument" },
    );
  });

  it("refuses to delete a plan referenced by a license or history with the exact message", async () => {
    const db = new FakeDb().when('"referenced"', [{ referenced: true }]);
    await refused(
      run(db, platform, "DeleteLicensePlan", { id: "plan-pro" }),
      "failed-precondition",
      "This plan is referenced by existing licenses or history and cannot be deleted. Deactivate it instead.",
    );
    assert.ok(!db.calls.some((c) => /^DELETE/i.test(c.sql.trim())));
  });

  it("deletes an unreferenced plan", async () => {
    const db = new FakeDb()
      .when('"referenced"', [{ referenced: false }])
      .when("delete from license_plan", [{ id: "p1" }]);
    assert.deepEqual(await run(db, platform, "DeleteLicensePlan", { id: "p1" }), {
      licensePlan_delete: { id: "p1" },
    });
  });

  it("maps a foreign-key refusal at delete time to the same precondition", async () => {
    const db = new FakeDb()
      .when('"referenced"', [{ referenced: false }])
      .whenCall((c) => {
        if (c.sql.startsWith("DELETE FROM license_plan")) {
          throw Object.assign(new Error("fk"), { code: "23503" });
        }
        return undefined;
      });
    await refused(
      run(db, platform, "DeleteLicensePlan", { id: "p1" }),
      "failed-precondition",
      "This plan is referenced by existing licenses or history and cannot be deleted. Deactivate it instead.",
    );
  });
});

/** Organization with one org row and an existing active plan the license can move to. */
const orgExists = () => new FakeDb().when(ORG_ROW, [{ id: "o1" }]);
const assignVars = {
  organizationId: "o1",
  planId: "plan-pro",
  startDate: "2026-01-01",
  expiryDate: "2026-12-31",
  negotiatedPrice: 100,
  maintenancePrice: 10,
};

describe("AssignOrganizationLicense", () => {
  it("rejects an expiry that is not after the start, and invalid dates or prices", async () => {
    await refused(
      run(orgExists(), platform, "AssignOrganizationLicense", { ...assignVars, expiryDate: "2026-01-01" }),
      "invalid-argument",
      "The expiry date must be after the start date.",
    );
    await assert.rejects(
      run(orgExists(), platform, "AssignOrganizationLicense", { ...assignVars, startDate: "2026-02-30" }),
      { code: "invalid-argument" },
    );
    await assert.rejects(
      run(orgExists(), platform, "AssignOrganizationLicense", { ...assignVars, negotiatedPrice: -1 }),
      { code: "invalid-argument" },
    );
    await assert.rejects(
      run(orgExists(), platform, "AssignOrganizationLicense", { ...assignVars, maintenancePrice: 1e12 + 1 }),
      { code: "invalid-argument" },
    );
  });

  it("refuses an unknown organization", async () => {
    await refused(
      run(new FakeDb(), platform, "AssignOrganizationLicense", assignVars),
      "not-found",
      "Organization not found.",
    );
  });

  it("refuses an organization that already has a license", async () => {
    const db = orgExists().when(LICENSE_EXISTS, [{ id: "ol0" }]);
    await refused(
      run(db, platform, "AssignOrganizationLicense", assignVars),
      "already-exists",
      "This organization already has a license.",
    );
  });

  it("refuses an inactive or unknown plan", async () => {
    const inactive = orgExists().when(PLAN_ROW, [{ id: "plan-pro", level: 3, status: "inactive" }]);
    await refused(
      run(inactive, platform, "AssignOrganizationLicense", assignVars),
      "failed-precondition",
      "Select an active license plan.",
    );
    await refused(
      run(orgExists(), platform, "AssignOrganizationLicense", assignVars),
      "failed-precondition",
      "Select an active license plan.",
    );
  });

  it("writes the license and one assigned history row in one transaction", async () => {
    const db = orgExists()
      .when(PLAN_ROW, [{ id: "plan-pro", level: 3, status: "active" }])
      .when("insert into organization_license", [{ id: "ol1" }]);
    const res = await run(db, platform, "AssignOrganizationLicense", assignVars);
    assert.deepEqual(res, { organizationLicense_insert: { id: "ol1" } });
    assert.equal(db.transactions, 1);
    const history = db.calls.find((c) => /insert into license_history/i.test(c.sql))!;
    assert.deepEqual(history.params, [
      "o1",
      "assigned",
      "plan-pro",
      "2026-01-01",
      "2026-12-31",
      100,
      10,
    ]);
  });

  it("maps a unique violation on insert to the already-exists message", async () => {
    const db = orgExists()
      .when(PLAN_ROW, [{ id: "plan-pro", level: 3, status: "active" }])
      .whenCall((c) => {
        if (c.sql.startsWith("INSERT INTO organization_license")) {
          throw uniqueViolation("organization_license_organization_id_key");
        }
        return undefined;
      });
    await refused(
      run(db, platform, "AssignOrganizationLicense", assignVars),
      "already-exists",
      "This organization already has a license.",
    );
  });
});

describe("ChangeOrganizationLicensePlan", () => {
  const changeVars = { organizationId: "o1", targetPlanId: "plan-enterprise", negotiatedPrice: 150, maintenancePrice: 15 };

  it("refuses when the organization has no license", async () => {
    await refused(
      run(new FakeDb(), platform, "ChangeOrganizationLicensePlan", changeVars),
      "failed-precondition",
      "This organization does not have a license.",
    );
  });

  it("refuses a target that is not strictly higher, not active, or missing", async () => {
    const licensed = (target: Record<string, unknown> | null) => {
      const db = new FakeDb().when(LICENSE_LOCK, [usableLicense({ planLevel: 3 })]);
      if (target) db.when(PLAN_ROW, [target]);
      return db;
    };
    const message = "Only a higher-level active plan can be selected.";
    await refused(
      run(licensed({ id: "plan-enterprise", level: 3, status: "active" }), platform, "ChangeOrganizationLicensePlan", changeVars),
      "failed-precondition",
      message,
    );
    await refused(
      run(licensed({ id: "plan-enterprise", level: 1, status: "active" }), platform, "ChangeOrganizationLicensePlan", changeVars),
      "failed-precondition",
      message,
    );
    await refused(
      run(licensed({ id: "plan-enterprise", level: 5, status: "inactive" }), platform, "ChangeOrganizationLicensePlan", changeVars),
      "failed-precondition",
      message,
    );
    await refused(
      run(licensed(null), platform, "ChangeOrganizationLicensePlan", changeVars),
      "failed-precondition",
      message,
    );
  });

  it("moves to a higher active plan, keeps the dates, and writes plan_changed", async () => {
    const db = new FakeDb()
      .when(LICENSE_LOCK, [usableLicense({ planLevel: 3 })])
      .when(PLAN_ROW, [{ id: "plan-enterprise", level: 5, status: "active" }]);
    const res = await run(db, platform, "ChangeOrganizationLicensePlan", changeVars);
    assert.deepEqual(res, { organizationLicense_update: { id: "ol1" } });
    const update = db.calls.find((c) => /^UPDATE organization_license/.test(c.sql.trim()))!;
    assert.deepEqual(update.params, ["ol1", "plan-enterprise", 150, 15]);
    const history = db.calls.find((c) => /insert into license_history/i.test(c.sql))!;
    assert.deepEqual(history.params, [
      "o1",
      "plan_changed",
      "plan-enterprise",
      "2026-01-01",
      "2027-12-31",
      150,
      15,
    ]);
  });
});

describe("ModifyOrganizationCommercialTerms", () => {
  const vars = { organizationId: "o1", negotiatedPrice: 100, maintenancePrice: 10 };

  it("refuses when the organization has no license", async () => {
    await refused(
      run(new FakeDb(), platform, "ModifyOrganizationCommercialTerms", vars),
      "failed-precondition",
      "This organization does not have a license.",
    );
  });

  it("is a no-op with no update and no history row when the prices are unchanged", async () => {
    const db = new FakeDb().when(LICENSE_LOCK, [usableLicense()]);
    assert.deepEqual(await run(db, platform, "ModifyOrganizationCommercialTerms", vars), {
      organizationLicense_update: { id: "ol1" },
    });
    assert.equal(db.calls.length, 1);
    assert.equal(db.calls.some((c) => /^UPDATE/.test(c.sql.trim())), false);
    assert.equal(db.calls.some((c) => /insert into license_history/i.test(c.sql)), false);
  });

  it("updates the prices and writes commercial_terms_modified when they change", async () => {
    const db = new FakeDb().when(LICENSE_LOCK, [usableLicense()]);
    await run(db, platform, "ModifyOrganizationCommercialTerms", { ...vars, maintenancePrice: 12 });
    assert.deepEqual(db.calls[1].params, ["ol1", 100, 12]);
    const history = db.calls.find((c) => /insert into license_history/i.test(c.sql))!;
    assert.deepEqual(history.params, [
      "o1",
      "commercial_terms_modified",
      "plan-pro",
      "2026-01-01",
      "2027-12-31",
      100,
      12,
    ]);
  });
});

describe("RenewOrganizationLicense", () => {
  const renewVars = {
    organizationId: "o1",
    planId: "plan-pro",
    newStartDate: "2026-12-01",
    newExpiryDate: "2027-11-30",
    negotiatedPrice: 120,
    maintenancePrice: 12,
  };
  /** A term ending 2026-11-30, active today (2026-11-15). */
  const endingNov = () =>
    new FakeDb()
      .when(LICENSE_LOCK, [usableLicense({ expiryDate: "2026-11-30" })])
      .when(PLAN_ROW, [{ id: "plan-pro", level: 3, status: "active" }]);

  it("refuses when the organization has no license", async () => {
    await refused(
      run(new FakeDb(), platform, "RenewOrganizationLicense", renewVars),
      "failed-precondition",
      "This organization does not have a license.",
    );
  });

  it("rejects a new start that is not after the current expiry, or an expiry not after the start", async () => {
    const message = "The renewal must start after the current expiry date and end after its start date.";
    await refused(
      run(endingNov(), platform, "RenewOrganizationLicense", { ...renewVars, newStartDate: "2026-11-30" }),
      "invalid-argument",
      message,
    );
    await refused(
      run(endingNov(), platform, "RenewOrganizationLicense", { ...renewVars, newExpiryDate: "2026-12-01" }),
      "invalid-argument",
      message,
    );
  });

  it("refuses an inactive renewal plan", async () => {
    const db = new FakeDb()
      .when(LICENSE_LOCK, [usableLicense({ expiryDate: "2026-11-30" })])
      .when(PLAN_ROW, [{ id: "plan-pro", level: 3, status: "inactive" }]);
    await refused(
      run(db, platform, "RenewOrganizationLicense", renewVars),
      "failed-precondition",
      "Select an active license plan.",
    );
  });

  it("extends a usable term back-to-back: keeps the start, moves the expiry, writes renewed", async () => {
    const db = endingNov();
    const res = await run(db, platform, "RenewOrganizationLicense", renewVars);
    assert.deepEqual(res, { organizationLicense_update: { id: "ol1" } });
    const update = db.calls.find((c) => /^UPDATE organization_license/.test(c.sql.trim()))!;
    assert.deepEqual(update.params, ["ol1", "plan-pro", "2026-01-01", "2027-11-30", 120, 12]);
    const history = db.calls.find((c) => /insert into license_history/i.test(c.sql))!;
    assert.deepEqual(history.params, ["o1", "renewed", "plan-pro", "2026-01-01", "2027-11-30", 120, 12]);
  });

  it("takes the new start when the renewal is not the day after expiry", async () => {
    const db = endingNov();
    await run(db, platform, "RenewOrganizationLicense", { ...renewVars, newStartDate: "2026-12-05" });
    const update = db.calls.find((c) => /^UPDATE organization_license/.test(c.sql.trim()))!;
    assert.deepEqual(update.params, ["ol1", "plan-pro", "2026-12-05", "2027-11-30", 120, 12]);
  });
});

describe("GetOrganizationLicense and GetOrganizationLicenseHistory", () => {
  it("returns null when no license exists", async () => {
    assert.deepEqual(
      await run(new FakeDb(), platform, "GetOrganizationLicense", { organizationId: "o1" }),
      { organizationLicense: null },
    );
  });

  it("derives the status on the server from today and nests the live plan", async () => {
    const db = new FakeDb().when(LICENSE_ROW, [
      {
        id: "ol1",
        organizationId: "o1",
        planId: "plan-pro",
        startDate: "2026-11-01",
        expiryDate: "2026-12-10",
        negotiatedPrice: 100,
        maintenancePrice: 10,
        planCode: "PLN-A",
        planName: "Pro",
        planLevel: 3,
        planMaxStores: 5,
        planMaxUsers: 75,
        planStatus: "active",
        today: "2026-11-15",
      },
    ]);
    const res = (await run(db, platform, "GetOrganizationLicense", { organizationId: "o1" })) as {
      organizationLicense: Record<string, unknown>;
    };
    assert.deepEqual(res.organizationLicense, {
      id: "ol1",
      organizationId: "o1",
      planId: "plan-pro",
      startDate: "2026-11-01",
      expiryDate: "2026-12-10",
      negotiatedPrice: 100,
      maintenancePrice: 10,
      status: "expiring_soon",
      plan: { id: "plan-pro", planCode: "PLN-A", name: "Pro", level: 3, maxStores: 5, maxUsers: 75, status: "active" },
    });
  });

  it("returns history newest first from the live plan", async () => {
    const rows = [
      { id: "h2", eventType: "renewed", planName: "Pro" },
      { id: "h1", eventType: "assigned", planName: "Basic" },
    ];
    const db = new FakeDb().when("from license_history h", rows);
    assert.deepEqual(await run(db, platform, "GetOrganizationLicenseHistory", { organizationId: "o1" }), {
      licenseHistory: rows,
    });
    assert.match(db.calls[0].sql, /ORDER BY h\.event_at DESC/);
    assert.match(db.calls[0].sql, /JOIN license_plan p ON p\.id = h\.plan_id/);
  });
});
