import { calendarDayNumber } from "./calendarDate";

/**
 * License status and usability rules. Pure: the caller passes "today" as a
 * YYYY-MM-DD calendar date read from SQL as LICENSE_TODAY_SQL, so every rule
 * uses the same Asia/Kolkata business day as the database.
 * Mirrors OmniRetail functions/src/licenses/licenseStatus.ts.
 */

/** Licenses roll over at midnight in India, not midnight UTC. */
export const LICENSE_TIME_ZONE = "Asia/Kolkata";

/** SQL expression for today's date in the license time zone. */
export const LICENSE_TODAY_SQL = `(now() AT TIME ZONE '${LICENSE_TIME_ZONE}')::date`;

/** An active license whose expiry is within this many days (inclusive) is "expiring_soon". */
export const EXPIRING_SOON_DAYS = 30;

export type LicenseStatus =
  | "not_assigned"
  | "not_yet_active"
  | "active"
  | "expiring_soon"
  | "expired";

export function deriveLicenseStatus(
  startDate: string | null | undefined,
  expiryDate: string | null | undefined,
  today: string,
): LicenseStatus {
  if (!startDate || !expiryDate) return "not_assigned";
  const start = calendarDayNumber(startDate);
  const expiry = calendarDayNumber(expiryDate);
  const now = calendarDayNumber(today);
  if (Number.isNaN(start) || Number.isNaN(expiry) || Number.isNaN(now)) return "not_assigned";
  if (now < start) return "not_yet_active";
  if (now > expiry) return "expired";
  if (expiry - now <= EXPIRING_SOON_DAYS) return "expiring_soon";
  return "active";
}

export interface LicenseUsability {
  startDate: string | null | undefined;
  expiryDate: string | null | undefined;
  planStatus: string | null | undefined;
  today: string;
}

/**
 * A license grants access and capacity only while its plan is active and today
 * falls inside the inclusive start..expiry window. An expiring-soon license is
 * still usable.
 */
export function isLicenseUsable(license: LicenseUsability): boolean {
  if (license.planStatus !== "active") return false;
  const status = deriveLicenseStatus(license.startDate, license.expiryDate, license.today);
  return status === "active" || status === "expiring_soon";
}
