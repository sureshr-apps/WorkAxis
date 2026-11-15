import { calendarDayNumber } from "./calendarDate";
import { isLicenseUsable } from "./licenseStatus";

/** Thrown when a renewal window is not calendar-valid or does not follow the current term. */
export class InvalidLicenseTermError extends Error {
  constructor() {
    super("invalid term");
    this.name = "InvalidLicenseTermError";
  }
}

export interface LicenseRenewalInput {
  currentStartDate: string;
  currentExpiryDate: string;
  currentPlanStatus: string | null | undefined;
  newStartDate: string;
  newExpiryDate: string;
  /** Today in the license time zone (YYYY-MM-DD). */
  today: string;
}

export interface LicenseRenewalTerm {
  /** Start date to store on the organization's single license row. */
  startDate: string;
  /** Expiry date to store on the organization's single license row. */
  expiryDate: string;
  /**
   * True when a usable term was renewed back-to-back: the start date is kept and
   * only the expiry moves, so access is not interrupted before the renewed term.
   */
  extendsCurrentTerm: boolean;
}

/**
 * Validates a renewal window and decides what the license row should hold.
 *
 * The new start must fall after the current expiry and the new expiry after the
 * new start. When the current term is usable today and the renewal starts the
 * day after the current expiry, the current start is kept and the expiry is
 * extended. Any other renewal takes the new start date.
 *
 * Throws InvalidLicenseTermError when the window is invalid.
 */
export function resolveLicenseRenewalTerm(input: LicenseRenewalInput): LicenseRenewalTerm {
  const currentExpiry = calendarDayNumber(input.currentExpiryDate);
  const newStart = calendarDayNumber(input.newStartDate);
  const newExpiry = calendarDayNumber(input.newExpiryDate);
  if (
    Number.isNaN(currentExpiry) ||
    Number.isNaN(newStart) ||
    Number.isNaN(newExpiry) ||
    newStart <= currentExpiry ||
    newExpiry <= newStart
  ) {
    throw new InvalidLicenseTermError();
  }

  const currentUsable = isLicenseUsable({
    startDate: input.currentStartDate,
    expiryDate: input.currentExpiryDate,
    planStatus: input.currentPlanStatus,
    today: input.today,
  });
  const contiguous = newStart - currentExpiry === 1;
  if (currentUsable && contiguous) {
    return {
      startDate: input.currentStartDate,
      expiryDate: input.newExpiryDate,
      extendsCurrentTerm: true,
    };
  }
  return {
    startDate: input.newStartDate,
    expiryDate: input.newExpiryDate,
    extendsCurrentTerm: false,
  };
}
