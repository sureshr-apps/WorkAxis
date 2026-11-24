import type { ShiftWindow } from "./shiftWindow";

const MINUTE_MS = 60_000;

/**
 * Organization attendance timing (organization_settings). Scheduled shift
 * end, the actual check-out and the session expiry are separate:
 * - reminder: shown to the employee this long after the shift ends;
 * - overdue: after the overtime allowance the open session is flagged for
 *   review, but a later check-out is still recorded;
 * - expiry: after the maximum session length the session is closed
 *   administratively (no check-out is invented) and needs a correction.
 */
export interface AttendanceTiming {
  earlyCheckInMinutes: number;
  checkoutReminderMinutes: number;
  overtimeReviewMinutes: number;
  maxSessionHours: number;
}

export const DEFAULT_ATTENDANCE_TIMING: AttendanceTiming = {
  earlyCheckInMinutes: 120,
  checkoutReminderMinutes: 30,
  overtimeReviewMinutes: 240,
  maxSessionHours: 16,
};

/** Timing from organization settings data, with defaults for missing or bad values. */
export function attendanceTiming(settings: Record<string, unknown> | undefined): AttendanceTiming {
  const pick = (key: keyof AttendanceTiming, min: number, max: number): number => {
    const value = settings?.[key];
    return typeof value === "number" && Number.isInteger(value) && value >= min && value <= max
      ? value
      : DEFAULT_ATTENDANCE_TIMING[key];
  };
  return {
    earlyCheckInMinutes: pick("earlyCheckInMinutes", 0, 480),
    checkoutReminderMinutes: pick("checkoutReminderMinutes", 0, 240),
    overtimeReviewMinutes: pick("overtimeReviewMinutes", 0, 720),
    maxSessionHours: pick("maxSessionHours", 8, 24),
  };
}

export interface SessionDeadlines {
  reminderAt: Date | null;
  overdueAt: Date | null;
  expiresAt: Date;
}

/** When an open session gets a reminder, is flagged overdue, and expires. */
export function sessionDeadlines(
  checkInAt: Date,
  window: ShiftWindow | null,
  timing: AttendanceTiming,
): SessionDeadlines {
  const expiresAt = new Date(checkInAt.getTime() + timing.maxSessionHours * 60 * MINUTE_MS);
  if (!window) return { reminderAt: null, overdueAt: null, expiresAt };
  const end = window.endAt.getTime();
  const capped = (minutes: number) => {
    const at = end + minutes * MINUTE_MS;
    return at < expiresAt.getTime() ? new Date(at) : null;
  };
  return {
    reminderAt: capped(timing.checkoutReminderMinutes),
    overdueAt: capped(timing.overtimeReviewMinutes),
    expiresAt,
  };
}
