import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { normalizeIdentity } from "../auth/aliasKeys";
import {
  runAccountUpdate,
  type AccountUpdateSteps,
} from "../accounts/updateWorkflow";

const before = normalizeIdentity({
  username: "alex",
  email: "old@example.com",
  phone: "+919876543210",
});
const after = normalizeIdentity({
  username: "alex",
  email: "new@example.com",
  phone: "+919876543210",
});

function fake(failAt?: "auth" | "sql" | "projection") {
  const aliases = new Map(
    before.aliasKeys.map((key) => [key, before.loginEmail]),
  );
  let authEmail = before.loginEmail;
  let completed = false;
  let sqlCommitted = false;
  const steps: AccountUpdateSteps = {
    reserve: async (identity) => {
      for (const key of identity.aliasKeys)
        aliases.set(key, identity.loginEmail);
    },
    updateAuth: async (identity) => {
      if (failAt === "auth" && identity.loginEmail === after.loginEmail)
        throw new Error("Auth unavailable");
      authEmail = identity.loginEmail;
    },
    commitSql: async () => {
      if (failAt === "sql") throw new Error("SQL rollback");
      sqlCommitted = true;
    },
    release: async (keys) => {
      keys.forEach((key) => aliases.delete(key));
    },
    project: async () => {
      if (failAt === "projection") throw new Error("Projection offline");
    },
    complete: async () => {
      completed = true;
    },
    recordRecoveryFailure: () => {},
  };
  return {
    steps,
    aliases,
    get authEmail() {
      return authEmail;
    },
    get completed() {
      return completed;
    },
    get sqlCommitted() {
      return sqlCommitted;
    },
  };
}

describe("account update recovery", () => {
  for (const failure of ["auth", "sql"] as const) {
    it(`restores username and phone alias targets after ${failure} failure`, async () => {
      const state = fake(failure);
      await assert.rejects(
        runAccountUpdate(before, after, "Old", "New", state.steps),
      );
      for (const key of before.aliasKeys)
        assert.equal(state.aliases.get(key), before.loginEmail);
      assert.equal(state.authEmail, before.loginEmail);
      assert.equal(state.aliases.has(after.loginEmail), false);
      assert.equal(state.completed, false); // durable reconciliation intent is retained
    });
  }
  it("reports a committed SQL edit as saved with pending projection", async () => {
    const state = fake("projection");
    assert.deepEqual(
      await runAccountUpdate(before, after, "Old", "New", state.steps),
      { projectionPending: true },
    );
    assert.equal(state.sqlCommitted, true);
    assert.equal(state.completed, false);
  });
  it("clears email while preserving username and phone login", async () => {
    const state = fake();
    const cleared = normalizeIdentity({
      username: before.username,
      phone: before.phone,
    });
    await runAccountUpdate(before, cleared, "Old", "Old", state.steps);
    assert.equal(state.authEmail, "alex@login.workaxis.invalid");
    assert.equal(state.aliases.has(before.loginEmail), false);
    assert.equal(state.aliases.get("alex"), state.authEmail);
    assert.equal(state.aliases.get(before.phone!), state.authEmail);
    assert.equal(state.completed, true);
  });
});
