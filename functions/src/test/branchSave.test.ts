import assert from "node:assert/strict";
import { it } from "node:test";
import { parseBranchSave, validateManagerPlan } from "../branches/savePlan";

it("branch manager validation completes before any persistence", () => {
  const manager = {
    id: "m1",
    authUid: "u1",
    organizationId: "o1",
    role: "branchManager",
    branchIds: ["b1"],
  };
  assert.throws(() => validateManagerPlan("o1", "b1", [manager], [], []));
  assert.throws(() =>
    validateManagerPlan(
      "o1",
      "b1",
      [],
      [{ ...manager, organizationId: "o2" }],
      ["m1"],
    ),
  );
  assert.throws(() => validateManagerPlan("o1", "b1", [], [], ["missing"]));
  assert.doesNotThrow(() =>
    validateManagerPlan(
      "o1",
      "b1",
      [{ ...manager, branchIds: ["b1", "b2"] }],
      [],
      [],
    ),
  );
});

it("branch save requires coordinates and validates caller scope", () => {
  const actor = {
    uid: "a",
    role: "orgAdmin" as const,
    organizationId: "o1",
    branchIds: [],
  };
  const draft = {
    requestId: "request-1",
    name: "Branch",
    code: "B1",
    location: "City",
    status: "active",
    isMainBranch: false,
    geofenceRadiusMeters: 100,
    latitude: 12.9716,
    longitude: 77.5946,
    managerIds: [],
  };
  assert.equal(parseBranchSave(actor, draft).data.latitude, 12.9716);
  assert.throws(() =>
    parseBranchSave(actor, { ...draft, latitude: null, longitude: null }),
  );
  assert.throws(() =>
    parseBranchSave({ ...actor, role: "branchManager" }, draft),
  );
  assert.throws(() => parseBranchSave(actor, { ...draft, longitude: null }));
  assert.throws(() =>
    parseBranchSave(actor, { ...draft, latitude: 0, longitude: 0 }),
  );
});
