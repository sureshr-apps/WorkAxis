import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { calendarDayNumber } from "../licenses/calendarDate";
import { deriveLicenseStatus, isLicenseUsable, LICENSE_TODAY_SQL } from "../licenses/licenseStatus";

const START = "2026-06-01";
const EXPIRY = "2026-12-31";

describe("deriveLicenseStatus", () => {
  it("is not_assigned without both dates or with an invalid date", () => {
    assert.equal(deriveLicenseStatus(null, EXPIRY, "2026-07-01"), "not_assigned");
    assert.equal(deriveLicenseStatus(START, undefined, "2026-07-01"), "not_assigned");
    assert.equal(deriveLicenseStatus("2026-02-30", EXPIRY, "2026-07-01"), "not_assigned");
    assert.equal(deriveLicenseStatus(START, EXPIRY, "not-a-date"), "not_assigned");
  });

  it("is not_yet_active before the start date", () => {
    assert.equal(deriveLicenseStatus(START, EXPIRY, "2026-05-31"), "not_yet_active");
  });

  it("is active on the start date and well before expiry", () => {
    assert.equal(deriveLicenseStatus(START, EXPIRY, START), "active");
    assert.equal(deriveLicenseStatus(START, EXPIRY, "2026-08-01"), "active");
  });

  it("is expiring_soon within 30 days of expiry, inclusive", () => {
    assert.equal(deriveLicenseStatus(START, EXPIRY, "2026-12-01"), "expiring_soon");
    assert.equal(deriveLicenseStatus(START, EXPIRY, "2026-12-31"), "expiring_soon");
  });

  it("is still active 31 days before expiry", () => {
    assert.equal(deriveLicenseStatus(START, EXPIRY, "2026-11-30"), "active");
  });

  it("is expired only after the expiry date", () => {
    assert.equal(deriveLicenseStatus(START, EXPIRY, "2027-01-01"), "expired");
  });

  it("treats a license that starts and expires within 30 days as expiring_soon on its start day", () => {
    assert.equal(deriveLicenseStatus("2026-11-15", "2026-11-16", "2026-11-15"), "expiring_soon");
  });
});

describe("isLicenseUsable", () => {
  const base = { startDate: START, expiryDate: EXPIRY, planStatus: "active", today: "2026-08-01" };

  it("grants access while the plan is active and today is inside the window", () => {
    assert.equal(isLicenseUsable(base), true);
    assert.equal(isLicenseUsable({ ...base, today: EXPIRY }), true);
  });

  it("keeps an expiring-soon license usable through the expiry date", () => {
    assert.equal(isLicenseUsable({ ...base, today: "2026-12-20" }), true);
  });

  it("denies an inactive or missing plan, even inside the window", () => {
    assert.equal(isLicenseUsable({ ...base, planStatus: "inactive" }), false);
    assert.equal(isLicenseUsable({ ...base, planStatus: null }), false);
  });

  it("denies a license outside its window", () => {
    assert.equal(isLicenseUsable({ ...base, today: "2026-05-31" }), false);
    assert.equal(isLicenseUsable({ ...base, today: "2027-01-01" }), false);
  });

  it("denies a missing license", () => {
    assert.equal(isLicenseUsable({ ...base, startDate: null, expiryDate: null }), false);
  });
});

describe("calendar helpers", () => {
  it("counts whole days and rejects impossible dates", () => {
    assert.equal(calendarDayNumber("1970-01-02"), 1);
    assert.equal(calendarDayNumber("2026-02-29"), Number.NaN);
    assert.equal(calendarDayNumber("2024-02-29") - calendarDayNumber("2024-02-28"), 1);
    assert.equal(calendarDayNumber("26-01-01"), Number.NaN);
  });

  it("reads today in the Asia/Kolkata calendar day", () => {
    assert.match(LICENSE_TODAY_SQL, /AT TIME ZONE 'Asia\/Kolkata'\)::date$/);
  });
});
