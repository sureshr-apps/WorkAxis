import { conflict, invalid, precondition } from "../errors";
import type { TimedBreak } from "./overtime";

const HOUR_MS = 60 * 60 * 1000;
/** No corrected session may be longer than this. */
export const MAX_CORRECTED_SESSION_HOURS = 24;

/** Check-out problems an employee may ask to correct. */
export const CORRECTABLE_CHECKOUT = ["missing", "late"] as const;

export interface CorrectableEntry {
  checkInAt: Date | null;
  checkOutAt: Date | null;
  breaks: readonly TimedBreak[];
  checkoutStatus: string;
  correctionStatus: string | null;
}

/**
 * Validates the check-out time an employee says they actually left at:
 * after check-in and every break, not in the future, earlier than a recorded
 * late check-out, and within the maximum corrected session length.
 */
export function validateRequestedCheckOut(entry: CorrectableEntry, requested: Date, now: Date): void {
  if (!(CORRECTABLE_CHECKOUT as readonly string[]).includes(entry.checkoutStatus)) {
    throw precondition("Only a missing or late check-out can be corrected.");
  }
  if (entry.correctionStatus === "pending") {
    throw conflict("A correction for this attendance is already waiting for review.");
  }
  if (!entry.checkInAt) throw precondition("This attendance has no check-in.");
  const at = requested.getTime();
  if (at <= entry.checkInAt.getTime()) throw invalid("The check-out time must be after the check-in.");
  const lastBreak = Math.max(0, ...entry.breaks.map((b) => (b.endAt ?? b.startAt).getTime()));
  if (at <= lastBreak) throw invalid("The check-out time must be after your last break.");
  if (at > now.getTime()) throw invalid("The check-out time cannot be in the future.");
  if (entry.checkOutAt && at >= entry.checkOutAt.getTime()) {
    throw invalid("The corrected check-out must be earlier than the recorded one.");
  }
  if (at - entry.checkInAt.getTime() > MAX_CORRECTED_SESSION_HOURS * HOUR_MS) {
    throw invalid(`A session cannot be longer than ${MAX_CORRECTED_SESSION_HOURS} hours.`);
  }
}

/** Approved overtime hours: the potential by default, at most the potential, two decimals. */
export function approvedOvertimeHours(potential: number, requested: number | undefined): number {
  if (!(potential > 0)) throw precondition("This attendance has no overtime to review.");
  const hours = requested ?? potential;
  if (!Number.isFinite(hours) || hours <= 0 || hours > potential + 1e-9) {
    throw invalid(`Approved overtime must be more than 0 and at most ${potential} hours.`);
  }
  if (Math.abs(hours * 100 - Math.round(hours * 100)) > 1e-6) {
    throw invalid("Approved overtime can have at most two decimal places.");
  }
  return Math.round(hours * 100) / 100;
}
