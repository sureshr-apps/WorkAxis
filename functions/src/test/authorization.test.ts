import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  assertCanManage,
  assertCanManageBranch,
  assertCanProvision,
} from "../auth/authorization";
import type { Actor, Role, Target } from "../auth/roles";

const owner: Actor = { uid: "owner", role: "platformOwner", branchIds: [] };
const padmin: Actor = { uid: "padmin", role: "platformAdmin", branchIds: [] };
const orgAdmin: Actor = { uid: "oa", role: "orgAdmin", organizationId: "o1", branchIds: [] };
const bm: Actor = { uid: "bm", role: "branchManager", organizationId: "o1", branchIds: ["b1", "b2"] };
const emp: Actor = { uid: "emp", role: "employee", organizationId: "o1", branchIds: ["b1"] };

const t = (role: Role, organizationId?: string, branchIds: string[] = [], uid?: string): Target => ({
  role,
  organizationId,
  branchIds,
  uid,
});
const allowed = (fn: () => void) => assert.doesNotThrow(fn);
const forbidden = (fn: () => void) => assert.throws(fn, { code: "permission-denied" });

describe("assertCanProvision", () => {
  it("nobody creates a platformOwner", () => {
    for (const a of [owner, padmin, orgAdmin, bm, emp]) forbidden(() => assertCanProvision(a, t("platformOwner")));
  });

  it("only the owner creates platform admins", () => {
    allowed(() => assertCanProvision(owner, t("platformAdmin")));
    forbidden(() => assertCanProvision(padmin, t("platformAdmin")));
    forbidden(() => assertCanProvision(orgAdmin, t("platformAdmin")));
  });

  it("platform roles create org admins for any org", () => {
    allowed(() => assertCanProvision(owner, t("orgAdmin", "o9")));
    allowed(() => assertCanProvision(padmin, t("orgAdmin", "o9")));
  });

  it("platform roles cannot create branch managers or employees", () => {
    forbidden(() => assertCanProvision(padmin, t("branchManager", "o1", ["b1"])));
    forbidden(() => assertCanProvision(owner, t("employee", "o1", ["b1"])));
  });

  it("org admin creates anything customer-side in own org only", () => {
    allowed(() => assertCanProvision(orgAdmin, t("orgAdmin", "o1")));
    allowed(() => assertCanProvision(orgAdmin, t("branchManager", "o1", ["b9"])));
    allowed(() => assertCanProvision(orgAdmin, t("employee", "o1", ["b9"])));
    forbidden(() => assertCanProvision(orgAdmin, t("employee", "o2", ["b1"])));
    forbidden(() => assertCanProvision(orgAdmin, t("orgAdmin", "o2")));
  });

  it("branch manager creates employees only within own branches", () => {
    allowed(() => assertCanProvision(bm, t("employee", "o1", ["b1"])));
    allowed(() => assertCanProvision(bm, t("employee", "o1", ["b1", "b2"])));
    forbidden(() => assertCanProvision(bm, t("employee", "o1", ["b1", "b3"])));
    forbidden(() => assertCanProvision(bm, t("employee", "o2", ["b1"])));
    forbidden(() => assertCanProvision(bm, t("branchManager", "o1", ["b1"])));
    forbidden(() => assertCanProvision(bm, t("orgAdmin", "o1")));
  });

  it("employees create nobody", () => {
    forbidden(() => assertCanProvision(emp, t("employee", "o1", ["b1"])));
  });

  it("validates shape", () => {
    assert.throws(() => assertCanProvision(orgAdmin, t("employee", "o1", [])), { code: "invalid-argument" });
    assert.throws(() => assertCanProvision(owner, t("platformAdmin", "o1")), { code: "invalid-argument" });
    assert.throws(() => assertCanProvision(owner, t("orgAdmin")), { code: "invalid-argument" });
  });
});

describe("assertCanManage", () => {
  it("nobody manages the platform owner", () => {
    for (const op of ["update", "resetPassword", "setStatus"] as const) {
      forbidden(() => assertCanManage(owner, t("platformOwner", undefined, [], "x"), op));
    }
  });

  it("owner manages platform admins and org admins; admin only org admins", () => {
    allowed(() => assertCanManage(owner, t("platformAdmin", undefined, [], "pa2"), "resetPassword"));
    allowed(() => assertCanManage(padmin, t("orgAdmin", "o1", [], "oa9"), "setStatus"));
    forbidden(() => assertCanManage(padmin, t("platformAdmin", undefined, [], "pa2"), "setStatus"));
    forbidden(() => assertCanManage(padmin, t("employee", "o1", ["b1"], "e9"), "resetPassword"));
  });

  it("org admin manages own-org users but not other orgs or platform users", () => {
    allowed(() => assertCanManage(orgAdmin, t("employee", "o1", ["b5"], "e1"), "update"));
    allowed(() => assertCanManage(orgAdmin, t("branchManager", "o1", ["b5"], "m1"), "setStatus"));
    forbidden(() => assertCanManage(orgAdmin, t("employee", "o2", ["b5"], "e2"), "update"));
    forbidden(() => assertCanManage(orgAdmin, t("platformAdmin", undefined, [], "p"), "update"));
  });

  it("branch manager manages employees sharing a branch only", () => {
    allowed(() => assertCanManage(bm, t("employee", "o1", ["b1", "b7"], "e1"), "resetPassword"));
    forbidden(() => assertCanManage(bm, t("employee", "o1", ["b7"], "e2"), "resetPassword"));
    forbidden(() => assertCanManage(bm, t("branchManager", "o1", ["b1"], "m2"), "update"));
    forbidden(() => assertCanManage(bm, t("employee", "o2", ["b1"], "e3"), "update"));
  });

  it("branch manager cannot grant branches outside own scope or promote", () => {
    const target = t("employee", "o1", ["b1"], "e1");
    allowed(() => assertCanManage(bm, target, "update", { branchIds: ["b1", "b2"] }));
    forbidden(() => assertCanManage(bm, target, "update", { branchIds: ["b1", "b3"] }));
    forbidden(() => assertCanManage(bm, target, "update", { role: "branchManager" }));
  });

  it("role changes follow the provisioning matrix", () => {
    const target = t("employee", "o1", ["b1"], "e1");
    allowed(() => assertCanManage(orgAdmin, target, "update", { role: "branchManager" }));
    forbidden(() => assertCanManage(orgAdmin, target, "update", { role: "platformAdmin" }));
    forbidden(() => assertCanManage(orgAdmin, target, "update", { role: "platformOwner" }));
  });

  it("no self role/branch/status changes; employees manage nobody", () => {
    forbidden(() => assertCanManage(orgAdmin, t("orgAdmin", "o1", [], "oa"), "setStatus"));
    forbidden(() => assertCanManage(orgAdmin, t("orgAdmin", "o1", [], "oa"), "update", { role: "employee" }));
    forbidden(() => assertCanManage(emp, t("employee", "o1", ["b1"], "other"), "update"));
  });
});

describe("assertCanManageBranch", () => {
  it("org admin of the org and branch manager of the branch only", () => {
    allowed(() => assertCanManageBranch(orgAdmin, { id: "b1", organizationId: "o1" }));
    allowed(() => assertCanManageBranch(bm, { id: "b2", organizationId: "o1" }));
    forbidden(() => assertCanManageBranch(bm, { id: "b3", organizationId: "o1" }));
    forbidden(() => assertCanManageBranch(orgAdmin, { id: "b1", organizationId: "o2" }));
    forbidden(() => assertCanManageBranch(padmin, { id: "b1", organizationId: "o1" }));
    forbidden(() => assertCanManageBranch(emp, { id: "b1", organizationId: "o1" }));
  });
});
