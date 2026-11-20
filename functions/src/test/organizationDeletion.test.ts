import assert from "node:assert/strict";
import { it } from "node:test";
import { isAuthUserNotFound } from "../organizations/deletionSteps";
import {
  runOrganizationDeletion,
  type OrganizationDeleteSteps,
} from "../organizations/deletionWorkflow";
import type { MemberRecord } from "../sql/members";

function member(authUid: string): MemberRecord {
  return {
    id: `m-${authUid}`,
    authUid,
    fullName: "N",
    username: authUid,
    email: `${authUid}@x.com`,
    role: "employee",
    status: "active",
    organizationId: "o1",
    licenseUsable: true,
    licenseToday: "2026-11-15",
    branchIds: [],
    activeBranchIds: [],
  };
}

/** Fake stores whose deletes tolerate already-done work, like production. */
function fakeSteps(
  opts: {
    failOn?: string;
    authError?: string;
    members?: readonly MemberRecord[];
  } = {},
) {
  const log: string[] = [];
  const authUsers = new Set(["u1", "u2"]);
  let firestoreMembers: readonly MemberRecord[] = [];
  const membersToDelete = opts.members ?? members;
  let failOn = opts.failOn;
  const maybeFail = (name: string) => {
    if (failOn === name) throw new Error(`boom ${name}`);
  };
  const steps: OrganizationDeleteSteps = {
    async suspend() {
      log.push("suspend");
    },
    async listMembers() {
      log.push("members");
      return [...membersToDelete];
    },
    async deleteFirestoreData(_organizationId, members) {
      maybeFail("firestore");
      firestoreMembers = members;
      log.push("firestore");
    },
    async deleteStorageObjects() {
      maybeFail("storage");
      log.push("storage");
    },
    async deleteMemberIdentity(m) {
      if (opts.authError && m.authUid === "u2") {
        const error = Object.assign(new Error("auth"), { code: opts.authError });
        if (!isAuthUserNotFound(error)) throw error;
      }
      authUsers.delete(m.authUid);
      log.push(`member:${m.authUid}`);
    },
    async deleteSql() {
      log.push("sql");
    },
  };
  return {
    steps,
    log,
    authUsers,
    get firestoreMembers() {
      return firestoreMembers;
    },
    clearFailure: () => {
      failOn = undefined;
    },
  };
}

const members = [member("u1"), member("u2")];

it("runs steps in order with SQL last", async () => {
  const f = fakeSteps();
  const r = await runOrganizationDeletion("o1", f.steps);
  assert.deepEqual(f.log, [
    "suspend",
    "members",
    "firestore",
    "storage",
    "member:u1",
    "member:u2",
    "sql",
  ]);
  assert.equal(r.membersCleaned, 2);
  assert.deepEqual(f.firestoreMembers, members);
});

it("rethrows an early failure without deleting SQL", async () => {
  const f = fakeSteps({ failOn: "storage" });
  await assert.rejects(
    runOrganizationDeletion("o1", f.steps),
    /boom storage/,
  );
  assert.ok(!f.log.includes("sql"));
  assert.equal(f.authUsers.size, 2);
});

it("does not delete member identities when Firestore cleanup fails", async () => {
  const f = fakeSteps({ failOn: "firestore" });
  await assert.rejects(
    runOrganizationDeletion("o1", f.steps),
    /boom firestore/,
  );
  assert.deepEqual(f.log, ["suspend", "members"]);
  assert.equal(f.authUsers.size, 2);
});

it("completes when re-run after a failure", async () => {
  const f = fakeSteps({ failOn: "firestore" });
  await assert.rejects(runOrganizationDeletion("o1", f.steps));
  f.clearFailure();
  const r = await runOrganizationDeletion("o1", f.steps);
  assert.equal(f.log.at(-1), "sql");
  assert.equal(r.membersCleaned, 2);
  assert.equal(f.authUsers.size, 0);
});

it("skips members without an auth uid", async () => {
  const f = fakeSteps({ members: [member("")] });
  const r = await runOrganizationDeletion("o1", f.steps);
  assert.equal(r.membersCleaned, 0);
});

it("tolerates auth/user-not-found but rethrows other auth errors", async () => {
  const ok = fakeSteps({ authError: "auth/user-not-found" });
  await runOrganizationDeletion("o1", ok.steps);
  assert.equal(ok.log.at(-1), "sql");

  const bad = fakeSteps({ authError: "auth/internal-error" });
  await assert.rejects(
    runOrganizationDeletion("o1", bad.steps),
    /auth/,
  );
  assert.ok(!bad.log.includes("sql"));
});
