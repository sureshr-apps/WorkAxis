import assert from "node:assert/strict";
import { afterEach, it } from "node:test";
import { setDbForTests } from "../db";
import { DomainError } from "../errors";
import { FakeDb } from "./fakeDb";
import { capacityDb } from "./licenseFixtures";
import {
  deleteMemberByAuthUid,
  getMemberByAuthUid,
  insertMember,
  replaceBranchAssignments,
  updateMemberWithAssignments,
} from "../sql/members";

afterEach(() => setDbForTests(undefined));

const norm = (s: string) => s.replace(/\s+/g, " ").trim();

it("getMemberByAuthUid maps the row and splits active branches", async () => {
  const db = new FakeDb()
    .when("FROM organization_member m", [
      {
        id: "m1",
        authUid: "u1",
        fullName: "Ann",
        username: "ann",
        email: "a@x.io",
        phone: null,
        role: "branchManager",
        status: "active",
        employeeCode: "EMP-10001",
        organizationId: "o1",
        organizationStatus: "active",
        licenseUsable: true,
        licenseStartDate: "2026-01-01",
        licenseExpiryDate: "2027-12-31",
        licensePlanStatus: "active",
        licenseToday: "2026-11-15",
      },
    ])
    .when("FROM user_branch_assignment a", [
      { memberId: "m1", branchId: "b1", branchStatus: "active" },
      { memberId: "m1", branchId: "b2", branchStatus: "suspended" },
    ]);
  setDbForTests(db);
  const m = await getMemberByAuthUid("u1");
  assert.deepEqual(m, {
    id: "m1",
    authUid: "u1",
    fullName: "Ann",
    username: "ann",
    email: "a@x.io",
    phone: undefined,
    role: "branchManager",
    status: "active",
    employeeCode: "EMP-10001",
    organizationId: "o1",
    organizationStatus: "active",
    licenseUsable: true,
    licenseStartDate: "2026-01-01",
    licenseExpiryDate: "2027-12-31",
    licensePlanStatus: "active",
    licenseToday: "2026-11-15",
    branchIds: ["b1", "b2"],
    activeBranchIds: ["b1"],
  });
  assert.deepEqual(db.calls[0].params, ["u1"]);
});

it("getMemberByAuthUid returns null for an unknown uid", async () => {
  setDbForTests(new FakeDb());
  assert.equal(await getMemberByAuthUid("nope"), null);
});

const newMember = (over: Record<string, unknown> = {}) => ({
  id: "m",
  authUid: "u",
  organizationId: "o1",
  fullName: "A",
  username: "a",
  email: "a@x.io",
  role: "employee" as const,
  ...over,
});

const employeeCodeViolation = () =>
  Object.assign(new Error("duplicate key"), {
    code: "23505",
    constraint: "organization_member_org_employee_code_uq",
  });

it("insertMember skips codes already taken manually", async () => {
  let seq = 10000;
  const db = capacityDb()
    .whenCall((c) =>
      c.sql.includes("SET employee_code_seq") ? [{ employee_code_seq: ++seq }] : undefined,
    )
    .whenCall((c) =>
      c.sql.includes("SELECT 1") && c.params[1] === "EMP-10001" ? [{ one: 1 }] : undefined,
    );
  setDbForTests(db);
  assert.equal(await insertMember(newMember(), []), "EMP-10002");
});

it("insertMember stores a supplied employee code without allocating", async () => {
  const db = capacityDb();
  setDbForTests(db);
  assert.equal(await insertMember(newMember({ employeeCode: " HR-7 " }), []), "HR-7");
  const insert = db.calls.find((c) => c.sql.startsWith("INSERT INTO organization_member"));
  assert.ok(insert);
  assert.equal(db.calls.some((c) => /employee_code_seq/.test(c.sql)), false);
  assert.equal(insert.params.at(-1), "HR-7");
});

it("insertMember maps an employee-code unique violation to a conflict", async () => {
  setDbForTests(
    capacityDb().whenCall((c) => {
      if (c.sql.startsWith("INSERT INTO organization_member")) throw employeeCodeViolation();
      return undefined;
    }),
  );
  await assert.rejects(
    insertMember(newMember({ employeeCode: "HR-7" }), []),
    (e) => e instanceof DomainError && e.message === "That employee ID is already in use.",
  );
});

it("insertMember leaves other unique violations untouched", async () => {
  setDbForTests(
    capacityDb().whenCall((c) => {
      if (c.sql.startsWith("INSERT INTO organization_member")) {
        throw Object.assign(new Error("duplicate key"), {
          code: "23505",
          constraint: "organization_member_email_key",
        });
      }
      return undefined;
    }),
  );
  await assert.rejects(
    insertMember(newMember({ employeeCode: "HR-7" }), []),
    (e) => !(e instanceof DomainError),
  );
});

it("insertMember rejects a malformed employee code before touching SQL", async () => {
  const db = new FakeDb();
  setDbForTests(db);
  await assert.rejects(insertMember(newMember({ employeeCode: "bad id" }), []), DomainError);
  assert.equal(db.calls.length, 0);
});

it("updateMember writes employeeCode and maps its unique violation", async () => {
  const db = new FakeDb().whenCall((c) => {
    if (c.sql.startsWith("UPDATE organization_member")) throw employeeCodeViolation();
    return undefined;
  });
  setDbForTests(db);
  await assert.rejects(
    updateMemberWithAssignments("m1", { employeeCode: "HR-7" }, ["b1"]),
    (e) => e instanceof DomainError && e.message === "That employee ID is already in use.",
  );
  assert.match(db.calls[0].sql, /employee_code = \$2/);
});

it("insertMember allocates the employee code in the same transaction as the insert", async () => {
  const db = capacityDb().when("SET employee_code_seq", [{ employee_code_seq: 10007 }]);
  setDbForTests(db);
  const code = await insertMember(
    {
      id: "m1",
      authUid: "u1",
      organizationId: "o1",
      fullName: "Ann",
      username: "ann",
      email: "a@x.io",
      role: "branchManager",
    },
    ["b1", "b2"],
  );
  assert.equal(code, "EMP-10007");
  assert.equal(db.transactions, 1);
  assert.equal(db.calls.length, 7);
  assert.match(db.calls[0].sql, /FROM organization WHERE id = \$1 FOR UPDATE/);
  // The license row is locked and the active count read before any allocation or insert.
  assert.match(db.calls[1].sql, /FOR UPDATE OF ol/);
  assert.match(db.calls[2].sql, /FROM organization_member/);
  assert.match(
    norm(db.calls[3].sql),
    /^UPDATE organization SET employee_code_seq = employee_code_seq \+ 1 WHERE id = \$1 RETURNING/,
  );
  assert.deepEqual(db.calls[3].params, ["o1"]);
  assert.match(db.calls[4].sql, /SELECT 1 FROM organization_member/);
  assert.match(
    norm(db.calls[5].sql),
    /^INSERT INTO organization_member \(id, auth_uid, organization_id, full_name, username, email, role, employee_code, status, created_at\)/,
  );
  assert.deepEqual(db.calls[5].params, [
    "m1",
    "u1",
    "o1",
    "Ann",
    "ann",
    "a@x.io",
    "branchManager",
    "EMP-10007",
  ]);
  assert.match(db.calls[6].sql, /INSERT INTO user_branch_assignment \(member_id, branch_id, assigned_at\)/);
  assert.deepEqual(db.calls[6].params, ["m1", ["b1", "b2"]]);
});

it("insertMember without branches skips the assignment insert", async () => {
  const db = new FakeDb();
  setDbForTests(db);
  await insertMember(
    {
      id: "m1",
      authUid: "u1",
      fullName: "A",
      username: "a",
      email: "a@x.io",
      role: "platformAdmin",
    },
    [],
  );
  assert.equal(db.calls.length, 1);
  assert.doesNotMatch(db.calls[0].sql, /organization_id|employee_code/);
  // Live tables have no SQL default for created_at, so the insert must set it.
  assert.match(norm(db.calls[0].sql), /, status, created_at\) VALUES \(.*, 'active', now\(\)\)$/);
});

it("updateMemberWithAssignments patches, clears and reinserts in one transaction", async () => {
  const db = new FakeDb();
  setDbForTests(db);
  await updateMemberWithAssignments("m1", { fullName: "New", phone: null }, [
    "b1",
  ]);
  assert.equal(db.transactions, 1);
  assert.deepEqual(
    db.calls.map((c) => norm(c.sql).split(" ").slice(0, 3).join(" ")),
    [
      "UPDATE organization_member SET",
      "DELETE FROM user_branch_assignment",
      "INSERT INTO user_branch_assignment",
    ],
  );
  assert.deepEqual(db.calls[0].params, ["m1", "New", null]);
});

it("replaceBranchAssignments with no branches only clears", async () => {
  const db = new FakeDb();
  setDbForTests(db);
  await replaceBranchAssignments("m1", []);
  assert.equal(db.transactions, 1);
  assert.equal(db.calls.length, 1);
});

it("deleteMemberByAuthUid removes assignments before the member, atomically", async () => {
  const db = new FakeDb();
  setDbForTests(db);
  await deleteMemberByAuthUid("u1");
  assert.equal(db.transactions, 1);
  assert.match(db.calls[0].sql, /DELETE FROM user_branch_assignment/);
  assert.match(db.calls[1].sql, /DELETE FROM organization_member/);
});
