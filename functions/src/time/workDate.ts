import { BUSINESS_TIMEZONE } from "../config";

/** `YYYY-MM-DD` of `instant` in the business timezone. */
export function workDateString(instant: Date, timeZone = BUSINESS_TIMEZONE): string {
  // The en-CA locale formats dates as YYYY-MM-DD.
  return new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(instant);
}

/** The instant at which `dateString` starts in Asia/Kolkata (UTC+05:30, no DST). */
export function workDateStart(dateString: string): Date {
  return new Date(`${dateString}T00:00:00+05:30`);
}
