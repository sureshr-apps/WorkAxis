import assert from "node:assert/strict";
import { afterEach, describe, it } from "node:test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { effectiveStatus, resolveActor } from "../auth/actor";
import { parseBranchSave } from "../branches/savePlan";
import { setDbForTests } from "../db";
import { commitBranchSave } from "../sql/branchSave";
import { getMemberByAuthUid, insertMember, type MemberRecord, updateMember } from "../sql/members";
import { FakeDb } from "./fakeDb";
import { capacityDb, usableLicense } from "./licenseFixtures";

afterEach(() => setDbForTests(undefined));

const USER_LIMIT = (max: number) =>
  `This organization has reached its plan limit of ${max} active users. Deactivate an existing administrator or employee before adding or activating another user.`;
const NO_PLAN_USERS =
  "This organization does not have an active license plan. Assign an active license before adding or activating users.";
const STORE_LIMIT = (max: number) =>
  `This organization has reached its plan limit of ${max} active stores. Deactivate an existing store before adding or activating another store.`;
const NO_PLAN_STORES =
  "This organization does not have an active license plan. Assign an active license before adding or activating stores.";

async function refusedWith(p: Promise<unknown>, message: string): Promise<void> {
  await assert.rejects(p, (e: { code?: string; message?: string }) => {
    assert.equal(e.code, "failed-precondition");
    assert.equal(e.message, message);
    return true;
  });
}

const sqlOf = (db: FakeDb) => db.calls.map((c) => c.sql.replace(/\s+/g, " ").trim());
const locked = (db: FakeDb) => sqlOf(db).some((s) => s.includes("FOR UPDATE OF ol"));

const memberRow = (over: Record<string, unknown> = {}) => ({
  id: "m1",
  authUid: "u1",
  fullName: "Ann",
  username: "ann",
  email: "a@x.io",
  phone: null,
  role: "orgAdmin",
  status: "active",
  employeeCode: "EMP-10001",
  organizationId: "o1",
  organizationStatus: "active",
  licenseUsable: true,
  licenseStartDate: "2026-01-01",
  licenseExpiryDate: "2027-12-31",
  licensePlanStatus: "active",
  licenseToday: "2026-11-15",
  ...over,
});

const request = (uid: string) => ({ auth: { uid } }) as unknown as CallableRequest<unknown>;

/** Refusal from resolveActor: a permission-denied error carrying the given message. */
async function refusedActor(over: Record<string, unknown>, message: string): Promise<void> {
  setDbForTests(new FakeDb().when("from organization_member m", [memberRow(over)]));
  await assert.rejects(resolveActor(request("u1")), (e: { code?: string; message?: string }) => {
    assert.equal(e.code, "permission-denied");
    assert.equal(e.message, message);
    return true;
  });
}

describe("sign-in and claims honour the organization license", () => {
  it("maps licenseUsable from the member row", async () => {
    setDbForTests(new FakeDb().when("from organization_member m", [memberRow({ licenseUsable: true })]));
    assert.equal((await getMemberByAuthUid("u1"))?.licenseUsable, true);
    setDbForTests(new FakeDb().when("from organization_member m", [memberRow({ licenseUsable: null })]));
    assert.equal((await getMemberByAuthUid("u1"))?.licenseUsable, false);
  });

  it("refuses an organization member whose license has expired with the expired message", async () => {
    await refusedActor(
      { licenseExpiryDate: "2026-11-01" },
      "Your organization's license has expired. Contact your administrator.",
    );
  });

  it("refuses an organization member whose license plan is inactive with the inactive message", async () => {
    await refusedActor(
      { licensePlanStatus: "inactive", licenseUsable: false },
      "Your organization's license is not active. Contact your administrator.",
    );
  });

  it("refuses an organization member with no license with the inactive message", async () => {
    await refusedActor(
      { licenseStartDate: null, licenseExpiryDate: null, licensePlanStatus: null, licenseUsable: false },
      "Your organization's license is not active. Contact your administrator.",
    );
  });

  it("refuses a suspended organization with the suspended message", async () => {
    await refusedActor(
      { organizationStatus: "suspended", licenseUsable: true },
      "Your organization is suspended. Contact your administrator.",
    );
  });

  it("refuses a disabled member with the account message", async () => {
    await refusedActor(
      { status: "suspended" },
      "Your account is disabled. Contact your administrator.",
    );
  });

  it("allows an organization member whose license is usable", async () => {
    setDbForTests(new FakeDb().when("from organization_member m", [memberRow()]));
    assert.deepEqual(await resolveActor(request("u1")), {
      uid: "u1",
      role: "orgAdmin",
      organizationId: "o1",
      branchIds: [],
    });
  });

  it("allows platform users regardless of any license", async () => {
    setDbForTests(
      new FakeDb().when(
        "from organization_member m",
        [memberRow({ role: "platformAdmin", organizationId: null, organizationStatus: null, licenseUsable: false })],
      ),
    );
    const actor = await resolveActor(request("u1"));
    assert.equal(actor.role, "platformAdmin");
  });

  it("reports an unusable license as suspended in the projection status", () => {
    const base: MemberRecord = {
      id: "m1",
      authUid: "u1",
      fullName: "A",
      username: "a",
      email: "a@x.io",
      role: "employee",
      status: "active",
      organizationId: "o1",
      organizationStatus: "active",
      licenseUsable: true,
      licenseToday: "2026-11-15",
      branchIds: [],
      activeBranchIds: [],
    };
    assert.equal(effectiveStatus(base), "active");
    assert.equal(effectiveStatus({ ...base, licenseUsable: false }), "suspended");
    assert.equal(
      effectiveStatus({ ...base, role: "platformOwner", organizationId: undefined, licenseUsable: false }),
      "active",
    );
  });
});

describe("member capacity", () => {
  const newMember = {
    id: "m2",
    authUid: "u2",
    organizationId: "o1",
    fullName: "Bo",
    username: "bo",
    email: "b@x.io",
    role: "employee" as const,
  };

  it("refuses a new member at the plan's user limit, before any insert", async () => {
    const db = capacityDb({ activeMembers: 10 });
    setDbForTests(db);
    await assert.rejects(insertMember(newMember, []), (e: { message?: string; code?: string }) => {
      assert.equal(e.code, "failed-precondition");
      assert.equal(e.message, USER_LIMIT(10));
      return true;
    });
    assert.ok(!sqlOf(db).some((s) => s.startsWith("INSERT INTO organization_member")));
    assert.equal(db.transactions, 1);
  });

  it("adds a member below the limit, counting active members under the license lock", async () => {
    const db = capacityDb({ activeMembers: 9 }).when("set employee_code_seq", [{ employee_code_seq: 10001 }]);
    setDbForTests(db);
    assert.equal(await insertMember(newMember, []), "EMP-10001");
    const order = sqlOf(db);
    const lock = order.findIndex((s) => s.includes("FOR UPDATE OF ol"));
    const count = order.findIndex((s) => s.includes('"activeCount" FROM organization_member'));
    const insert = order.findIndex((s) => s.startsWith("INSERT INTO organization_member"));
    assert.ok(lock >= 0 && lock < count && count < insert);
  });

  it("refuses when the organization has no license", async () => {
    setDbForTests(capacityDb({ license: null }));
    await refusedWith(insertMember(newMember, []), NO_PLAN_USERS);
  });

  it("refuses when the license has expired", async () => {
    setDbForTests(capacityDb({ license: usableLicense({ expiryDate: "2026-11-01" }) }));
    await refusedWith(insertMember(newMember, []), NO_PLAN_USERS);
  });

  it("does not count or check platform users, which have no organization", async () => {
    const db = new FakeDb();
    setDbForTests(db);
    await insertMember(
      { id: "p1", authUid: "pu", fullName: "P", username: "p", email: "p@x.io", role: "platformAdmin" },
      [],
    );
    assert.equal(locked(db), false);
  });

  /** The member lookup used by the status change: a member with the given status in o1. */
  const memberWithStatus = (status: "active" | "suspended") =>
    new FakeDb().when("from organization_member where id", [{ organizationId: "o1", status }]);

  it("refuses reactivating a suspended member at the user limit", async () => {
    const db = capacityDb({ activeMembers: 10 }).when("from organization_member where id", [
      { organizationId: "o1", status: "suspended" },
    ]);
    setDbForTests(db);
    await refusedWith(updateMember("m1", { status: "active" }), USER_LIMIT(10));
    assert.ok(!sqlOf(db).some((s) => s.startsWith("UPDATE organization_member SET status")));
  });

  it("reactivates a suspended member when there is room", async () => {
    const db = capacityDb({ activeMembers: 9 }).when("from organization_member where id", [
      { organizationId: "o1", status: "suspended" },
    ]);
    setDbForTests(db);
    await updateMember("m1", { status: "active" });
    assert.ok(sqlOf(db).some((s) => s.startsWith("UPDATE organization_member SET status")));
  });

  it("does not re-check a member that is already active", async () => {
    const db = memberWithStatus("active");
    setDbForTests(db);
    await updateMember("m1", { status: "active" });
    assert.equal(locked(db), false);
    assert.ok(sqlOf(db).some((s) => s.startsWith("UPDATE organization_member SET status")));
  });

  it("does not check suspension", async () => {
    const db = memberWithStatus("active");
    setDbForTests(db);
    await updateMember("m1", { status: "suspended" });
    assert.equal(locked(db), false);
  });
});

describe("store capacity", () => {
  const actor = { uid: "admin", role: "orgAdmin" as const, organizationId: "o1", branchIds: [] };
  const draft = {
    name: "Branch",
    code: "B1",
    location: "City",
    isMainBranch: false,
    geofenceRadiusMeters: 100,
    latitude: null,
    longitude: null,
    managerIds: [] as string[],
  };
  const BRANCH_LOCK = "FROM branch WHERE id = $1 FOR UPDATE";

  const create = (status: "active" | "suspended") =>
    parseBranchSave(actor, { ...draft, status, requestId: "req-12345" });
  const update = (status: "active" | "suspended") =>
    parseBranchSave(actor, { ...draft, status, id: "b1", managerIds: [] });

  it("refuses creating an active store at the plan's store limit, before any insert", async () => {
    const db = capacityDb({ activeBranches: 5 }).when(BRANCH_LOCK, []);
    setDbForTests(db);
    await assert.rejects(commitBranchSave(create("active"), []), (e: { message?: string; code?: string }) => {
      assert.equal(e.code, "failed-precondition");
      assert.equal(e.message, STORE_LIMIT(5));
      return true;
    });
    assert.ok(!sqlOf(db).some((s) => s.startsWith("INSERT INTO branch")));
  });

  it("creates a suspended store even at the active store limit", async () => {
    const db = capacityDb({ activeBranches: 5 }).when(BRANCH_LOCK, []);
    setDbForTests(db);
    await commitBranchSave(create("suspended"), []);
    assert.ok(sqlOf(db).some((s) => s.startsWith("INSERT INTO branch")));
  });

  it("refuses any new store without a usable license", async () => {
    const db = capacityDb({ license: null }).when(BRANCH_LOCK, []);
    setDbForTests(db);
    await refusedWith(commitBranchSave(create("suspended"), []), NO_PLAN_STORES);
  });

  it("refuses reactivating a suspended store at the store limit", async () => {
    const db = capacityDb({ activeBranches: 5 }).when(BRANCH_LOCK, [
      { organizationId: "o1", status: "suspended" },
    ]);
    setDbForTests(db);
    await refusedWith(commitBranchSave(update("active"), []), STORE_LIMIT(5));
    assert.ok(!sqlOf(db).some((s) => s.startsWith("UPDATE branch SET")));
  });

  it("does not check an active store that stays active", async () => {
    const db = capacityDb({ activeBranches: 5 }).when(BRANCH_LOCK, [
      { organizationId: "o1", status: "active" },
    ]);
    setDbForTests(db);
    await commitBranchSave(update("active"), []);
    assert.equal(locked(db), false);
    assert.ok(sqlOf(db).some((s) => s.startsWith("UPDATE branch SET")));
  });
});
