import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { assertInsideGeofence, assertPunchAllowed } from "../attendance/punchRules";
import { distanceMeters, evaluateGeofence } from "../geo/distance";

const bangalore = { latitude: 12.9716, longitude: 77.5946 };

describe("distanceMeters", () => {
  it("is zero for identical points", () => {
    assert.equal(distanceMeters(bangalore, bangalore), 0);
  });

  it("matches a known long distance (Bangalore to Chennai ~290 km)", () => {
    const chennai = { latitude: 13.0827, longitude: 80.2707 };
    const km = distanceMeters(bangalore, chennai) / 1000;
    assert.ok(km > 285 && km < 295, `got ${km}`);
  });

  it("measures ~111 m per 0.001 degree of latitude", () => {
    const d = distanceMeters(bangalore, { latitude: 12.9726, longitude: 77.5946 });
    assert.ok(d > 109 && d < 113, `got ${d}`);
  });
});

describe("evaluateGeofence / assertInsideGeofence", () => {
  const branch = { ...bangalore, geofenceRadiusMeters: 125 };

  it("is inside within the radius and outside beyond it", () => {
    const near = { latitude: 12.9721, longitude: 77.5946 }; // ~55 m
    const far = { latitude: 12.9740, longitude: 77.5946 }; // ~267 m
    assert.equal(evaluateGeofence(near, bangalore, 125).inside, true);
    assert.equal(evaluateGeofence(far, bangalore, 125).inside, false);
    assert.doesNotThrow(() => assertInsideGeofence(near, 10, branch));
    assert.throws(() => assertInsideGeofence(far, 10, branch), { code: "failed-precondition" });
  });

  it("rejects poor GPS accuracy and unconfigured branches", () => {
    assert.throws(() => assertInsideGeofence(bangalore, 500, branch), { code: "failed-precondition" });
    assert.throws(() => assertInsideGeofence(bangalore, 5, { geofenceRadiusMeters: 100 }), {
      code: "failed-precondition",
    });
    assert.throws(
      () => assertInsideGeofence(bangalore, 5, { latitude: 0, longitude: 0, geofenceRadiusMeters: 100 }),
      { code: "failed-precondition" },
    );
  });
});

describe("assertPunchAllowed", () => {
  const t0 = new Date("2026-11-07T04:00:00Z");
  const empty = { breaks: [] };

  it("enforces the punch state machine", () => {
    assert.doesNotThrow(() => assertPunchAllowed("checkIn", empty));
    assert.throws(() => assertPunchAllowed("checkIn", { checkInAt: t0, breaks: [] }));
    assert.throws(() => assertPunchAllowed("checkOut", empty));
    assert.doesNotThrow(() => assertPunchAllowed("checkOut", { checkInAt: t0, breaks: [] }));
    assert.throws(() => assertPunchAllowed("checkOut", { checkInAt: t0, checkOutAt: t0, breaks: [] }));
    assert.throws(() => assertPunchAllowed("breakEnd", { checkInAt: t0, breaks: [] }));
    assert.doesNotThrow(() => assertPunchAllowed("breakEnd", { checkInAt: t0, breaks: [{ startAt: t0 }] }));
    assert.throws(() => assertPunchAllowed("checkOut", { checkInAt: t0, breaks: [{ startAt: t0 }] }));
    assert.throws(() => assertPunchAllowed("breakStart", { checkInAt: t0, breaks: [{ startAt: t0 }] }));
  });
});
