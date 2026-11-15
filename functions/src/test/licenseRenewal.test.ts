import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  InvalidLicenseTermError,
  type LicenseRenewalInput,
  resolveLicenseRenewalTerm,
} from "../licenses/licenseRenewal";

/** A term running 2026-01-01 to 2026-11-30 on an active plan; today is 2026-11-15. */
const current = {
  currentStartDate: "2026-01-01",
  currentExpiryDate: "2026-11-30",
  currentPlanStatus: "active",
  today: "2026-11-15",
};

const renewal = (over: Partial<LicenseRenewalInput>): LicenseRenewalInput => ({
  ...current,
  newStartDate: "2026-12-01",
  newExpiryDate: "2027-11-30",
  ...over,
});

describe("resolveLicenseRenewalTerm validation", () => {
  it("requires the new start to be after the current expiry", () => {
    assert.throws(
      () => resolveLicenseRenewalTerm(renewal({ newStartDate: "2026-11-30" })),
      InvalidLicenseTermError,
    );
    assert.throws(
      () => resolveLicenseRenewalTerm(renewal({ newStartDate: "2026-10-01" })),
      InvalidLicenseTermError,
    );
  });

  it("requires the new expiry to be after the new start", () => {
    assert.throws(
      () => resolveLicenseRenewalTerm(renewal({ newExpiryDate: "2026-12-01" })),
      InvalidLicenseTermError,
    );
  });

  it("rejects dates that are not real calendar dates", () => {
    assert.throws(
      () => resolveLicenseRenewalTerm(renewal({ newStartDate: "2026-02-30" })),
      InvalidLicenseTermError,
    );
  });
});

describe("resolveLicenseRenewalTerm terms", () => {
  it("extends a usable term when the renewal starts the day after expiry", () => {
    const term = resolveLicenseRenewalTerm(renewal({}));
    assert.deepEqual(term, {
      startDate: "2026-01-01",
      expiryDate: "2027-11-30",
      extendsCurrentTerm: true,
    });
  });

  it("takes the new start when the renewal is not the day after expiry", () => {
    const term = resolveLicenseRenewalTerm(renewal({ newStartDate: "2026-12-02" }));
    assert.deepEqual(term, {
      startDate: "2026-12-02",
      expiryDate: "2027-11-30",
      extendsCurrentTerm: false,
    });
  });

  it("takes the new start when the current term is no longer usable", () => {
    const expired = resolveLicenseRenewalTerm(renewal({ today: "2026-12-05" }));
    assert.equal(expired.startDate, "2026-12-01");
    assert.equal(expired.extendsCurrentTerm, false);
  });

  it("takes the new start when the current plan is inactive", () => {
    const term = resolveLicenseRenewalTerm(renewal({ currentPlanStatus: "inactive" }));
    assert.equal(term.startDate, "2026-12-01");
    assert.equal(term.extendsCurrentTerm, false);
  });
});
