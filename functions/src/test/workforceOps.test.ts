import assert from "node:assert/strict";
import { test } from "node:test";
import type { Firestore } from "firebase-admin/firestore";
import type { Actor } from "../auth/roles";
import { runOperation } from "../data/dispatch";
import { operations } from "../data/registry";
import { backfillEmployeeWorkforceHistory } from "../data/ops/workforce";
import { FakeDb } from "./fakeDb";

const admin: Actor = {
  uid: "admin-uid",
  role: "orgAdmin",
  organizationId: "org-1",
  branchIds: [],
};

const member = {
  id: "member-1",
  authUid: "employee-uid",
  fullName: "Sample Employee",
  role: "employee",
  organizationId: "org-1",
};

function run(db: FakeDb, actor: Actor, op: string, vars: Record<string, unknown> = {}) {
  return runOperation(
    operations,
    { db, actor, requireEmployeeAssetAcknowledgement: async () => false },
    { op, vars },
  );
}

function businessDate(value: Date): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Kolkata",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(value);
}

function dateAfter(value: string, days: number): string {
  const [year, month, day] = value.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day + days));
  return date.toISOString().slice(0, 10);
}

function baseDb({
  schedules = [],
  compensations = [],
}: {
  schedules?: Record<string, unknown>[];
  compensations?: Record<string, unknown>[];
} = {}): FakeDb {
  return new FakeDb().whenCall(({ sql }) => {
    const normalized = sql.toLowerCase();
    if (normalized.includes("from organization_member") && normalized.includes("for update")) {
      return [{ id: member.id }];
    }
    if (normalized.includes("from organization_member") && normalized.includes("where id = $1")) {
      return [member];
    }
    if (normalized.includes("from organization_member") && normalized.includes("role in ('employee', 'branchmanager')")) {
      return [{ id: member.id, authUid: member.authUid, role: member.role }];
    }
    if (normalized.includes("from employee_schedule_history")) return schedules;
    if (normalized.includes("from employee_compensation_history")) return compensations;
    return undefined;
  });
}

class MemoryFirestore {
  readonly values = new Map<string, Record<string, unknown>>();
  readonly writes: Array<{ path: string; data: Record<string, unknown> }> = [];

  collection(name: string) {
    return {
      doc: (id: string) => {
        const path = `${name}/${id}`;
        return {
          get: async () => {
            const value = this.values.get(path);
            return { exists: value != null, data: () => value };
          },
          set: async (data: Record<string, unknown>) => {
            this.writes.push({ path, data });
            this.values.set(path, { ...(this.values.get(path) ?? {}), ...data });
          },
        };
      },
    };
  }
}

test("workforce backfill imports current values with Sunday off from cutover date", async () => {
  const now = new Date("2026-11-22T10:00:00.000Z");
  const firestore = new MemoryFirestore();
  firestore.values.set("users/employee-uid", {
    joiningDate: "2019-07-01",
    dailyWorkHours: 7.5,
    shiftHours: "08:30 AM - 04:00 PM",
  });
  firestore.values.set("employee_private/employee-uid", { salary: 45_000 });
  const db = baseDb();

  const result = await backfillEmployeeWorkforceHistory({
    db,
    actor: admin,
    firestore: firestore as unknown as Firestore,
    now,
  });

  assert.equal(result.membersProcessed, 1);
  assert.equal(result.schedulesCreated, 1);
  assert.equal(result.salariesCreated, 1);
  assert.equal(result.legacyProfilesCleaned, 1);
  assert.equal(result.effectiveFrom, "2026-11-22");
  const schedule = db.calls.find((call) => call.sql.includes("INSERT INTO employee_schedule_history"));
  const compensation = db.calls.find((call) => call.sql.includes("INSERT INTO employee_compensation_history"));
  assert.ok(schedule);
  assert.ok(compensation);
  assert.deepEqual(schedule.params, [
    member.id,
    "2026-11-22",
    7.5,
    "08:30 AM - 04:00 PM",
    admin.uid,
  ]);
  assert.deepEqual(compensation.params, [member.id, "2026-11-22", 45_000, admin.uid]);
  assert.ok(firestore.writes.some((write) => write.path === "users/employee-uid"));
  assert.ok(firestore.writes.some((write) => write.path === "employee_private/employee-uid"));
});

test("backfill preserves a legacy salary when no valid salary history was imported", async () => {
  const firestore = new MemoryFirestore();
  firestore.values.set("users/employee-uid", { dailyWorkHours: 8 });
  firestore.values.set("employee_private/employee-uid", { salary: "not-a-salary" });

  const result = await backfillEmployeeWorkforceHistory({
    db: baseDb(),
    actor: admin,
    firestore: firestore as unknown as Firestore,
    now: new Date("2026-11-22T10:00:00.000Z"),
  });

  assert.equal(result.salariesCreated, 0);
  assert.equal(result.legacyProfilesCleaned, 1);
  assert.equal(
    firestore.writes.some((write) => write.path === "employee_private/employee-uid"),
    false,
  );
});

test("backfill does not count members without legacy documents as cleaned", async () => {
  const result = await backfillEmployeeWorkforceHistory({
    db: baseDb(),
    actor: admin,
    firestore: new MemoryFirestore() as unknown as Firestore,
    now: new Date("2026-11-22T10:00:00.000Z"),
  });

  assert.equal(result.membersProcessed, 1);
  assert.equal(result.schedulesCreated, 1);
  assert.equal(result.legacyProfilesCleaned, 0);
});

test("schedule edits close surrounding ranges without touching compensation or member fields", async () => {
  const today = businessDate(new Date());
  const effectiveFrom = dateAfter(today, 2);
  const successorDate = dateAfter(today, 10);
  const db = baseDb({
    schedules: [
      { id: "previous", effectiveFrom: dateAfter(today, -10), effectiveTo: null },
      { id: "successor", effectiveFrom: successorDate, effectiveTo: null },
    ],
  });

  const result = await run(db, admin, "SaveEmployeeSchedule", {
    memberId: member.id,
    effectiveFrom,
    dailyWorkHours: 7.5,
    shiftHours: "08:30 AM - 04:00 PM",
    weeklyDayOff: 2,
  });

  assert.deepEqual(result, { saved: true });
  const closePrevious = db.calls.find((call) =>
    call.sql.toLowerCase().startsWith("update employee_schedule_history set effective_to"),
  );
  const insertSchedule = db.calls.find((call) =>
    call.sql.includes("INSERT INTO employee_schedule_history"),
  );
  assert.deepEqual(closePrevious?.params, ["previous", effectiveFrom]);
  assert.deepEqual(insertSchedule?.params, [
    member.id,
    effectiveFrom,
    successorDate,
    7.5,
    "08:30 AM - 04:00 PM",
    2,
    admin.uid,
  ]);
  assert.equal(db.calls.some((call) => /employee_compensation_history|UPDATE organization_member/i.test(call.sql)), false);
});

test("compensation edits write only salary history and reject past effective dates", async () => {
  const db = baseDb();
  const result = await run(db, admin, "SaveEmployeeCompensation", {
    memberId: member.id,
    effectiveFrom: dateAfter(businessDate(new Date()), 1),
    monthlySalary: 52_000,
  });

  assert.deepEqual(result, { saved: true });
  assert.equal(db.calls.some((call) => call.sql.includes("INSERT INTO employee_compensation_history")), true);
  assert.equal(db.calls.some((call) => call.sql.includes("employee_schedule_history")), false);
  assert.equal(db.calls.some((call) => /UPDATE organization_member/i.test(call.sql)), false);

  await assert.rejects(
    run(baseDb(), admin, "SaveEmployeeCompensation", {
      memberId: member.id,
      effectiveFrom: "2000-01-01",
      monthlySalary: 52_000,
    }),
    (error: { code?: string }) => error.code === "failed-precondition",
  );
});

test("a Branch Manager cannot read workforce history through an unassigned branch", async () => {
  const manager: Actor = {
    uid: "manager-uid",
    role: "branchManager",
    organizationId: "org-1",
    branchIds: ["branch-1"],
  };
  const db = baseDb();

  await assert.rejects(
    run(db, manager, "GetEmployeeWorkforceHistory", {
      memberId: member.id,
      activeBranchId: "branch-2",
    }),
    (error: { code?: string }) => error.code === "permission-denied",
  );
});
