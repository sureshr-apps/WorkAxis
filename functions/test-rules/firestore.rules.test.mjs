// Run: firebase emulators:exec --only firestore "npm --prefix functions run test:rules"
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { after, before, beforeEach, describe, it } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { Timestamp, serverTimestamp, doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs } from "firebase/firestore";

const RULES = readFileSync(new URL("../../firestore.rules", import.meta.url), "utf8");

const claims = {
  owner: { role: "platformOwner", status: "active", branchIds: [] },
  padmin: { role: "platformAdmin", status: "active", branchIds: [] },
  orgAdmin: { role: "orgAdmin", organizationId: "o1", status: "active", branchIds: [] },
  orgAdmin2: { role: "orgAdmin", organizationId: "o2", status: "active", branchIds: [] },
  bm: { role: "branchManager", organizationId: "o1", status: "active", branchIds: ["b1", "b2"] },
  emp: { role: "employee", organizationId: "o1", status: "active", branchIds: ["b1"] },
  suspendedBm: { role: "branchManager", organizationId: "o1", status: "suspended", branchIds: ["b1"] },
  suspendedAdmin: { role: "orgAdmin", organizationId: "o1", status: "suspended", branchIds: [] },
};

let env;
const db = (name) => env.authenticatedContext(name, claims[name]).firestore();
const anon = () => env.unauthenticatedContext().firestore();

const entry = (over = {}) => ({
  id: "e1",
  organizationId: "o1",
  branchId: "b1",
  employeeId: "emp",
  employeeName: "Alex",
  workDate: Timestamp.fromDate(new Date()),
  workDateString: "2026-11-07",
  status: "present",
  reviewStatus: "none",
  checkInAt: Timestamp.fromDate(new Date()),
  ...over,
});

before(async () => {
  env = await initializeTestEnvironment({ projectId: "workaxis-rules-test", firestore: { rules: RULES } });
});
after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, "user_aliases/alex.rivera"), { userId: "emp", email: "a@x.com" });
    await setDoc(doc(d, "users/emp"), { name: "Alex", role: "employee", status: "active", organizationId: "o1", branchIds: ["b1"] });
    await setDoc(doc(d, "users/emp2"), { name: "Bo", role: "employee", status: "active", organizationId: "o1", branchIds: ["b9"] });
    await setDoc(doc(d, "users/other"), { name: "Zed", role: "employee", status: "active", organizationId: "o2", branchIds: ["b5"] });
    await setDoc(doc(d, "attendance_entries/e1"), entry());
    await setDoc(doc(d, "attendance_entries/e2"), entry({ id: "e2", branchId: "b9", employeeId: "emp2" }));
    await setDoc(doc(d, "attendance_entries/e3"), entry({ id: "e3", organizationId: "o2", branchId: "b5", employeeId: "other" }));
  });
});

describe("user_aliases", () => {
  it("is fully closed to every client, including anonymous and platform owner", async () => {
    await assertFails(getDoc(doc(anon(), "user_aliases/alex.rivera")));
    for (const who of ["owner", "padmin", "orgAdmin", "bm", "emp"]) {
      await assertFails(getDoc(doc(db(who), "user_aliases/alex.rivera")));
      await assertFails(getDocs(collection(db(who), "user_aliases")));
      await assertFails(setDoc(doc(db(who), "user_aliases/new"), { userId: "x", email: "x@x.com" }));
      await assertFails(updateDoc(doc(db(who), "user_aliases/alex.rivera"), { userId: "x" }));
      await assertFails(deleteDoc(doc(db(who), "user_aliases/alex.rivera")));
    }
  });
});

describe("users", () => {
  it("lets users read their own profile only", async () => {
    await assertSucceeds(getDoc(doc(db("emp"), "users/emp")));
    await assertFails(getDoc(doc(db("emp"), "users/emp2")));
    await assertFails(getDoc(doc(anon(), "users/emp")));
  });

  it("lets platform roles and same-org org admins read; not other orgs", async () => {
    await assertSucceeds(getDoc(doc(db("owner"), "users/other")));
    await assertSucceeds(getDoc(doc(db("padmin"), "users/emp")));
    await assertSucceeds(getDoc(doc(db("orgAdmin"), "users/emp")));
    await assertFails(getDoc(doc(db("orgAdmin"), "users/other")));
    await assertFails(getDoc(doc(db("orgAdmin2"), "users/emp")));
  });

  it("lets a branch manager read only employees sharing a branch", async () => {
    await assertSucceeds(getDoc(doc(db("bm"), "users/emp")));
    await assertFails(getDoc(doc(db("bm"), "users/emp2")));
  });

  it("supports constrained org-scoped list queries for org admins", async () => {
    const q = query(collection(db("orgAdmin"), "users"), where("organizationId", "==", "o1"));
    await assertSucceeds(getDocs(q));
    const bad = query(collection(db("orgAdmin"), "users"));
    await assertFails(getDocs(bad));
  });

  it("denies all client writes, even by platform owner or self", async () => {
    for (const who of ["owner", "orgAdmin", "emp"]) {
      await assertFails(setDoc(doc(db(who), "users/new"), { name: "N", role: "employee", status: "active" }));
      await assertFails(updateDoc(doc(db(who), "users/emp"), { role: "platformOwner" }));
      await assertFails(deleteDoc(doc(db(who), "users/emp")));
    }
  });

  it("denies suspended callers", async () => {
    await assertFails(getDoc(doc(db("suspendedAdmin"), "users/emp")));
  });
});

describe("attendance_entries read", () => {
  it("scopes reads by role", async () => {
    await assertSucceeds(getDoc(doc(db("owner"), "attendance_entries/e3")));
    await assertSucceeds(getDoc(doc(db("orgAdmin"), "attendance_entries/e2")));
    await assertFails(getDoc(doc(db("orgAdmin"), "attendance_entries/e3")));
    await assertSucceeds(getDoc(doc(db("bm"), "attendance_entries/e1")));
    await assertFails(getDoc(doc(db("bm"), "attendance_entries/e2"))); // branch b9 not assigned
    await assertFails(getDoc(doc(db("bm"), "attendance_entries/e3")));
    await assertSucceeds(getDoc(doc(db("emp"), "attendance_entries/e1"))); // own
    await assertFails(getDoc(doc(db("emp"), "attendance_entries/e2")));
  });

  it("denies suspended managers and admins", async () => {
    await assertFails(getDoc(doc(db("suspendedBm"), "attendance_entries/e1")));
    await assertFails(getDoc(doc(db("suspendedAdmin"), "attendance_entries/e1")));
  });
});

describe("attendance_entries write", () => {
  it("never lets employees or platform roles write directly", async () => {
    await assertFails(setDoc(doc(db("emp"), "attendance_entries/n1"), entry({ id: "n1" })));
    await assertFails(setDoc(doc(db("owner"), "attendance_entries/n2"), entry({ id: "n2" })));
    await assertFails(deleteDoc(doc(db("owner"), "attendance_entries/e1")));
    await assertFails(deleteDoc(doc(db("orgAdmin"), "attendance_entries/e1")));
  });

  const managerEntry = (over = {}) =>
    entry({
      id: "g1",
      employeeId: "emp",
      source: "manager-group",
      checkInAt: serverTimestamp(),
      createdAt: serverTimestamp(),
      workDate: Timestamp.fromDate(new Date(Date.now() - 60_000)),
      ...over,
    });

  it("denies direct group creates, including forged foreign employees", async () => {
    await assertFails(setDoc(doc(db("bm"), "attendance_entries/g1"), managerEntry()));
    await assertFails(setDoc(doc(db("bm"), "attendance_entries/other_2026-11-07"), managerEntry({ employeeId: "other" })));
    await assertFails(setDoc(doc(db("orgAdmin"), "attendance_entries/g5"), managerEntry()));
    await assertFails(setDoc(doc(db("bm"), "attendance_entries/g2"), managerEntry({ branchId: "b9" })));
    await assertFails(
      setDoc(doc(db("bm"), "attendance_entries/g3"), managerEntry({ checkInAt: Timestamp.fromDate(new Date()) })),
    );
    await assertFails(setDoc(doc(db("suspendedBm"), "attendance_entries/g4"), managerEntry()));
  });

  const review = (over = {}) => ({
    reviewStatus: "verified",
    reviewedBy: "Marcus",
    reviewedById: "bm",
    reviewedAt: serverTimestamp(),
    ...over,
  });

  it("allows review by in-scope managers/org admins with server time and own id", async () => {
    await assertSucceeds(updateDoc(doc(db("bm"), "attendance_entries/e1"), review()));
    await assertSucceeds(
      updateDoc(doc(db("orgAdmin"), "attendance_entries/e1"), review({ reviewedById: "orgAdmin" })),
    );
  });

  it("rejects out-of-scope, platform, suspended, forged-time and extra-field reviews", async () => {
    await assertFails(updateDoc(doc(db("bm"), "attendance_entries/e2"), review()));
    await assertFails(updateDoc(doc(db("owner"), "attendance_entries/e1"), review({ reviewedById: "owner" })));
    await assertFails(updateDoc(doc(db("suspendedBm"), "attendance_entries/e1"), review({ reviewedById: "suspendedBm" })));
    await assertFails(
      updateDoc(doc(db("bm"), "attendance_entries/e1"), review({ reviewedAt: Timestamp.fromDate(new Date(0)) })),
    );
    await assertFails(updateDoc(doc(db("bm"), "attendance_entries/e1"), review({ reviewedById: "someoneElse" })));
    await assertFails(updateDoc(doc(db("bm"), "attendance_entries/e1"), review({ status: "absent" })));
    await assertFails(updateDoc(doc(db("emp"), "attendance_entries/e1"), review({ reviewedById: "emp" })));
  });
});

describe("group_attendance_batches", () => {
  const batch = (over = {}) => ({
    id: "bt1",
    organizationId: "o1",
    branchId: "b1",
    workDate: "2026-11-07",
    shiftName: "Morning",
    attendeeCount: 3,
    createdBy: "Marcus",
    createdById: "bm",
    createdAt: serverTimestamp(),
    ...over,
  });

  it("denies every direct group audit create and update", async () => {
    await assertFails(setDoc(doc(db("bm"), "group_attendance_batches/bt1"), batch()));
    await assertFails(setDoc(doc(db("bm"), "group_attendance_batches/bt2"), batch({ branchId: "b9" })));
    await assertFails(
      setDoc(doc(db("bm"), "group_attendance_batches/bt3"), batch({ createdAt: Timestamp.fromDate(new Date()) })),
    );
    await assertFails(setDoc(doc(db("bm"), "group_attendance_batches/bt4"), batch({ createdById: "x" })));
    await assertFails(setDoc(doc(db("emp"), "group_attendance_batches/bt5"), batch({ createdById: "emp" })));
    await assertFails(setDoc(doc(db("suspendedBm"), "group_attendance_batches/bt6"), batch({ createdById: "suspendedBm" })));
    await assertFails(updateDoc(doc(db("bm"), "group_attendance_batches/bt1"), { shiftName: "Night" }));
    await assertFails(deleteDoc(doc(db("bm"), "group_attendance_batches/bt1")));
  });
});

describe("legacy and server-only collections", () => {
  it("denies attendance_punches and server-only collections to everyone", async () => {
    for (const path of [
      "attendance_punches/p1",
      "provision_requests/r1",
      "auth_rate_limits/k1",
      "kiosk_pairing_tokens/t1",
      "identity_sync_jobs/j1",
    ]) {
      await assertFails(setDoc(doc(db("owner"), path), { a: 1 }));
      await assertFails(getDoc(doc(db("owner"), path)));
    }
  });
});

assert.ok(true);

describe("settings", () => {
  const orgSettings = (over = {}) => ({
    organizationId: "o1",
    geofenceRadiusMeters: 150,
    gracePeriodMinutes: 15,
    allowBreaks: true,
    requireGeolocation: true,
    dailyDigest: true,
    returnAlerts: true,
    operationsEmail: null,
    emergencyPhone: "+919876543210",
    updatedBy: "orgAdmin",
    updatedAt: serverTimestamp(),
    ...over,
  });
  const platSettings = (over = {}) => ({
    sessionTimeoutMinutes: 60,
    maxLoginAttempts: 5,
    maintenanceMode: false,
    enforceStrongPasswords: true,
    updatedBy: "owner",
    updatedAt: serverTimestamp(),
    ...over,
  });

  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "organization_settings/o1"), { organizationId: "o1" });
      await setDoc(doc(ctx.firestore(), "platform_settings/global"), { maintenanceMode: false });
    });
  });

  it("organization settings: org admin of the org reads and writes", async () => {
    await assertSucceeds(getDoc(doc(db("orgAdmin"), "organization_settings/o1")));
    await assertSucceeds(setDoc(doc(db("orgAdmin"), "organization_settings/o1"), orgSettings()));
  });

  it("organization settings: platform reads but cannot write", async () => {
    await assertSucceeds(getDoc(doc(db("owner"), "organization_settings/o1")));
    await assertSucceeds(getDoc(doc(db("padmin"), "organization_settings/o1")));
    await assertFails(setDoc(doc(db("owner"), "organization_settings/o1"), orgSettings({ updatedBy: "owner" })));
  });

  it("organization settings: other roles and orgs are denied", async () => {
    await assertFails(getDoc(doc(db("orgAdmin2"), "organization_settings/o1")));
    await assertFails(setDoc(doc(db("orgAdmin2"), "organization_settings/o1"), orgSettings({ updatedBy: "orgAdmin2" })));
    for (const who of ["bm", "emp", "suspendedAdmin"]) {
      await assertFails(getDoc(doc(db(who), "organization_settings/o1")));
      await assertFails(setDoc(doc(db(who), "organization_settings/o1"), orgSettings({ updatedBy: who })));
    }
    await assertFails(getDoc(doc(anon(), "organization_settings/o1")));
  });

  it("organization settings: validates fields, ranges, stamps", async () => {
    const ref = () => doc(db("orgAdmin"), "organization_settings/o1");
    await assertFails(setDoc(ref(), orgSettings({ extra: 1 })));
    await assertFails(setDoc(ref(), orgSettings({ organizationId: "o2" })));
    await assertFails(setDoc(ref(), orgSettings({ geofenceRadiusMeters: 9 })));
    await assertFails(setDoc(ref(), orgSettings({ geofenceRadiusMeters: 5001 })));
    await assertFails(setDoc(ref(), orgSettings({ gracePeriodMinutes: 121 })));
    await assertFails(setDoc(ref(), orgSettings({ gracePeriodMinutes: -1 })));
    await assertFails(setDoc(ref(), orgSettings({ allowBreaks: "yes" })));
    await assertFails(setDoc(ref(), orgSettings({ updatedBy: "someoneElse" })));
    await assertFails(setDoc(ref(), orgSettings({ updatedAt: Timestamp.fromDate(new Date(0)) })));
    await assertSucceeds(setDoc(ref(), orgSettings({ geofenceRadiusMeters: 10, gracePeriodMinutes: 120 })));
    await assertFails(deleteDoc(ref()));
  });

  it("platform settings: platform roles read, only owner writes", async () => {
    await assertSucceeds(getDoc(doc(db("owner"), "platform_settings/global")));
    await assertSucceeds(getDoc(doc(db("padmin"), "platform_settings/global")));
    await assertSucceeds(setDoc(doc(db("owner"), "platform_settings/global"), platSettings()));
    await assertFails(setDoc(doc(db("padmin"), "platform_settings/global"), platSettings({ updatedBy: "padmin" })));
    for (const who of ["orgAdmin", "bm", "emp"]) {
      await assertFails(getDoc(doc(db(who), "platform_settings/global")));
      await assertFails(setDoc(doc(db(who), "platform_settings/global"), platSettings({ updatedBy: who })));
    }
    await assertFails(setDoc(doc(db("owner"), "platform_settings/other"), platSettings()));
  });

  it("platform settings: validates ranges and stamps", async () => {
    const ref = () => doc(db("owner"), "platform_settings/global");
    await assertFails(setDoc(ref(), platSettings({ sessionTimeoutMinutes: 4 })));
    await assertFails(setDoc(ref(), platSettings({ sessionTimeoutMinutes: 1441 })));
    await assertFails(setDoc(ref(), platSettings({ maxLoginAttempts: 2 })));
    await assertFails(setDoc(ref(), platSettings({ maxLoginAttempts: 11 })));
    await assertFails(setDoc(ref(), platSettings({ maintenanceMode: 1 })));
    await assertFails(setDoc(ref(), platSettings({ updatedBy: "x" })));
    await assertFails(setDoc(ref(), platSettings({ extra: true })));
    await assertSucceeds(setDoc(ref(), platSettings({ sessionTimeoutMinutes: 5, maxLoginAttempts: 10 })));
  });
});
