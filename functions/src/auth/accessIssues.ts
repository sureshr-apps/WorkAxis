import { deriveLicenseStatus, isLicenseUsable } from "../licenses/licenseStatus";
import { isPlatformRole, type Role } from "./roles";

/** Why a signed-in member is refused access. Each code has one user-facing message. */
export type AccessIssueCode =
  | "account_disabled"
  | "organization_suspended"
  | "organization_license_expired"
  | "organization_license_inactive";

/** The server is the source of these messages; the app shows them as received. */
export const ACCESS_ISSUE_MESSAGES: Record<AccessIssueCode, string> = {
  account_disabled: "Your account is disabled. Contact your administrator.",
  organization_suspended: "Your organization is suspended. Contact your administrator.",
  organization_license_expired: "Your organization's license has expired. Contact your administrator.",
  organization_license_inactive: "Your organization's license is not active. Contact your administrator.",
};

/** The member fields the access rules read. MemberRecord satisfies this shape. */
export interface AccessIssueSubject {
  role: Role;
  status: string;
  organizationStatus?: string;
  licenseStartDate?: string | null;
  licenseExpiryDate?: string | null;
  licensePlanStatus?: string | null;
}

/**
 * Returns why the member may not use the platform, or null when access is
 * allowed. Pure: [today] is the license-zone calendar date (YYYY-MM-DD) read
 * from SQL, so the license rules in licenseStatus.ts decide every date question.
 *
 * - The member must be active. Platform roles are refused only for this.
 * - The organization must be active (customer roles only).
 * - The license must be usable. When it exists but has expired, the reason is
 *   "expired"; no license, an inactive plan or a start date in the future is
 *   "inactive".
 */
export function accessIssueFor(subject: AccessIssueSubject, today: string): AccessIssueCode | null {
  if (subject.status !== "active") return "account_disabled";
  if (isPlatformRole(subject.role)) return null;
  if (subject.organizationStatus !== "active") return "organization_suspended";

  const license = {
    startDate: subject.licenseStartDate,
    expiryDate: subject.licenseExpiryDate,
    planStatus: subject.licensePlanStatus,
    today,
  };
  if (isLicenseUsable(license)) return null;

  const expired = subject.licensePlanStatus === "active"
    && deriveLicenseStatus(subject.licenseStartDate, subject.licenseExpiryDate, today) === "expired";
  return expired ? "organization_license_expired" : "organization_license_inactive";
}
