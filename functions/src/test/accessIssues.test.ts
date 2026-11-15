import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { ACCESS_ISSUE_MESSAGES, accessIssueFor, type AccessIssueSubject } from "../auth/accessIssues";

const TODAY = "2026-11-15";

/** An active employee in an active organization holding an active license valid today. */
const usable: AccessIssueSubject = {
  role: "employee",
  status: "active",
  organizationStatus: "active",
  licenseStartDate: "2026-01-01",
  licenseExpiryDate: "2027-12-31",
  licensePlanStatus: "active",
};

describe("accessIssueFor", () => {
  it("allows a member whose organization and license are usable", () => {
    assert.equal(accessIssueFor(usable, TODAY), null);
  });

  it("refuses an inactive member with account_disabled", () => {
    assert.equal(accessIssueFor({ ...usable, status: "suspended" }, TODAY), "account_disabled");
  });

  it("refuses a member of a suspended organization with organization_suspended", () => {
    assert.equal(accessIssueFor({ ...usable, organizationStatus: "suspended" }, TODAY), "organization_suspended");
  });

  it("refuses a member with no organization with organization_suspended", () => {
    assert.equal(accessIssueFor({ ...usable, organizationStatus: undefined }, TODAY), "organization_suspended");
  });

  it("reports an expired license as organization_license_expired", () => {
    assert.equal(
      accessIssueFor({ ...usable, licenseExpiryDate: "2026-11-14" }, TODAY),
      "organization_license_expired",
    );
  });

  it("reports an inactive plan with expired dates as organization_license_inactive, not expired", () => {
    assert.equal(
      accessIssueFor({ ...usable, licensePlanStatus: "inactive", licenseExpiryDate: "2026-11-14" }, TODAY),
      "organization_license_inactive",
    );
  });

  it("reports a license that has not started yet as organization_license_inactive", () => {
    assert.equal(
      accessIssueFor({ ...usable, licenseStartDate: "2026-12-01" }, TODAY),
      "organization_license_inactive",
    );
  });

  it("reports a missing license as organization_license_inactive", () => {
    assert.equal(
      accessIssueFor({ ...usable, licenseStartDate: null, licenseExpiryDate: null, licensePlanStatus: null }, TODAY),
      "organization_license_inactive",
    );
  });

  it("reports a license without an active plan as organization_license_inactive", () => {
    assert.equal(accessIssueFor({ ...usable, licensePlanStatus: null }, TODAY), "organization_license_inactive");
  });

  it("treats the start and expiry days as inclusive", () => {
    assert.equal(accessIssueFor({ ...usable, licenseStartDate: TODAY }, TODAY), null);
    assert.equal(accessIssueFor({ ...usable, licenseExpiryDate: TODAY }, TODAY), null);
  });

  it("keeps a license that expires soon usable", () => {
    assert.equal(accessIssueFor({ ...usable, licenseExpiryDate: "2026-12-01" }, TODAY), null);
  });

  it("checks the license against the supplied day, not the stored one", () => {
    assert.equal(accessIssueFor(usable, "2028-01-01"), "organization_license_expired");
  });

  it("never refuses platform roles for organization or license reasons", () => {
    const platformOnly: AccessIssueSubject[] = [
      { role: "platformOwner", status: "active" },
      { role: "platformAdmin", status: "active", organizationStatus: "suspended", licensePlanStatus: "active", licenseExpiryDate: "2020-01-01", licenseStartDate: "2019-01-01" },
    ];
    for (const subject of platformOnly) {
      assert.equal(accessIssueFor(subject, TODAY), null);
    }
  });

  it("still refuses an inactive platform user with account_disabled", () => {
    assert.equal(accessIssueFor({ role: "platformOwner", status: "suspended" }, TODAY), "account_disabled");
  });
});

describe("ACCESS_ISSUE_MESSAGES", () => {
  it("carries the exact user-facing text for every code", () => {
    assert.deepEqual(ACCESS_ISSUE_MESSAGES, {
      account_disabled: "Your account is disabled. Contact your administrator.",
      organization_suspended: "Your organization is suspended. Contact your administrator.",
      organization_license_expired: "Your organization's license has expired. Contact your administrator.",
      organization_license_inactive: "Your organization's license is not active. Contact your administrator.",
    });
  });
});
