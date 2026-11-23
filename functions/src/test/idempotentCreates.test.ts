import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { Actor } from "../auth/roles";
import { runOperation } from "../data/dispatch";
import { creationKey, idempotentCreate } from "../data/idempotency";
import { operations } from "../data/registry";
import { FakeDb, type RecordedCall } from "./fakeDb";

const employee: Actor = { uid: "e1", role: "employee", organizationId: "o1", branchIds: ["b1"] };
const REQUEST_ID = "0b8f6a52-4c1e-4b0f-9f3e-2f0a6b1c7d9e";

function run(db: FakeDb, op: string, vars: Record<string, unknown>) {
  return runOperation(
    operations,
    { db, actor: employee, requireEmployeeAssetAcknowledgement: async () => false },
    { op, vars },
  );
}

const SHA256 = /^[0-9a-f]{64}$/;

/**
 * A FakeDb that remembers the creation key and fingerprint of every inserted
 * row of [table], so a retried request can find what the first attempt saved.
 */
function rememberingDb(table: string) {
  const saved: { id: string; key: string; fingerprint: string }[] = [];
  const isInsert = (c: RecordedCall) => new RegExp(`insert into ${table}`, "i").test(c.sql);
  const db = new FakeDb()
    .whenCall((c) => {
      if (!/where creation_request_key/i.test(c.sql)) return undefined;
      return saved
        .filter((s) => s.key === c.params[0])
        .map((s) => ({ id: s.id, fingerprint: s.fingerprint }));
    })
    .whenCall((c) => {
      if (!isInsert(c)) return undefined;
      const [key, fingerprint] = c.params.filter((p) => typeof p === "string" && SHA256.test(p));
      const id = `${table}-${saved.length + 1}`;
      saved.push({ id, key: key as string, fingerprint: fingerprint as string });
      return [{ id }];
    });
  return { db, saved, inserts: () => db.calls.filter(isInsert).length };
}

describe("idempotentCreate", () => {
  const creation = { key: "k", fingerprint: "f" };

  it("creates without a creation key", async () => {
    let created = 0;
    const result = await idempotentCreate(new FakeDb(), undefined, async () => null, async () => ++created);
    assert.equal(result, 1);
  });

  it("replays a matching prior create instead of creating again", async () => {
    let created = 0;
    const result = await idempotentCreate(
      new FakeDb(),
      creation,
      async () => ({ fingerprint: "f", result: "first" }),
      async () => `new-${++created}`,
    );
    assert.equal(result, "first");
    assert.equal(created, 0);
  });

  it("rejects a reused request id with different details", async () => {
    await assert.rejects(
      idempotentCreate(
        new FakeDb(),
        creation,
        async () => ({ fingerprint: "other", result: "first" }),
        async () => "new",
      ),
      (e: { code?: string }) => e.code === "already-exists",
    );
  });

  it("returns the winner's result when a concurrent attempt hits the unique index", async () => {
    let lookups = 0;
    const result = await idempotentCreate(
      new FakeDb(),
      creation,
      async () => (++lookups === 1 ? null : { fingerprint: "f", result: "winner" }),
      async () => {
        throw Object.assign(new Error("duplicate key value"), { code: "23505" });
      },
    );
    assert.equal(result, "winner");
  });

  it("rethrows a unique violation that is not this request", async () => {
    await assert.rejects(
      idempotentCreate(new FakeDb(), creation, async () => null, async () => {
        throw Object.assign(new Error("duplicate key value"), { code: "23505" });
      }),
      /duplicate key/,
    );
  });

  it("scopes keys to the caller and ignores a missing request id", () => {
    const other: Actor = { ...employee, uid: "e2" };
    const a = creationKey(employee, { requestId: REQUEST_ID }, { x: 1 })!;
    const b = creationKey(other, { requestId: REQUEST_ID }, { x: 1 })!;
    assert.notEqual(a.key, b.key);
    assert.equal(a.fingerprint, b.fingerprint);
    assert.equal(creationKey(employee, {}, { x: 1 }), undefined);
  });
});

describe("retry-safe creates", () => {
  const returnVars = {
    branchId: "b1",
    invoiceNumber: "INV1",
    requestId: REQUEST_ID,
    items: [
      { productTitle: "Shoe", quantity: 2, unit: "pc", returnReason: "damaged" },
      { productTitle: "Sock", quantity: 1, unit: "pc", returnReason: "expired" },
    ],
  };

  function returnsDb() {
    const memory = rememberingDb("return_record");
    memory.db
      .when("from organization_member where auth_uid", [{ id: "mem1", authUid: "e1", fullName: "Eve" }])
      .when("from branch where id", [{ status: "active", organizationId: "o1" }]);
    return memory;
  }

  it("a retried return bill returns the first lines without saving again", async () => {
    const { db, inserts } = returnsDb();
    const first = await run(db, "SubmitReturnBatch", returnVars);
    const retry = await run(db, "SubmitReturnBatch", returnVars);
    assert.deepEqual(retry, first);
    assert.equal(inserts(), 2);
  });

  it("a reused request id with a changed bill is rejected", async () => {
    const { db, inserts } = returnsDb();
    await run(db, "SubmitReturnBatch", returnVars);
    await assert.rejects(
      run(db, "SubmitReturnBatch", { ...returnVars, invoiceNumber: "INV2" }),
      (e: { code?: string }) => e.code === "already-exists",
    );
    assert.equal(inserts(), 2);
  });

  it("returns without a request id are saved every time (older clients)", async () => {
    const { db, inserts } = returnsDb();
    const legacy = { ...returnVars, requestId: undefined };
    await run(db, "SubmitReturnBatch", legacy);
    await run(db, "SubmitReturnBatch", legacy);
    assert.equal(inserts(), 4);
  });

  it("a retried leave request returns the first request", async () => {
    const { db, inserts } = rememberingDb("leave_request");
    db.when("from branch where id", [{ status: "active", organizationId: "o1" }])
      .when("from organization_member where auth_uid", [{ id: "mem1", fullName: "Eve" }])
      .when("from leave_request r join branch", [{ id: "leave_request-1", status: "pending" }])
      .when("from leave_type", [{ id: "lt-sick" }]);
    const vars = {
      branchId: "b1",
      leaveTypeId: "lt-sick",
      startDate: "2026-11-24",
      endDate: "2026-11-25",
      reason: "Fever",
      requestId: REQUEST_ID,
    };
    const first = await run(db, "SubmitLeaveRequest", vars);
    const retry = await run(db, "SubmitLeaveRequest", vars);
    assert.deepEqual(retry, first);
    assert.equal(inserts(), 1);
  });
});
