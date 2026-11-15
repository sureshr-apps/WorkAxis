const DAY_MILLISECONDS = 24 * 60 * 60 * 1000;
const DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;

/**
 * Whole days since 1970-01-01 for a real YYYY-MM-DD calendar date, or NaN when
 * the value is not a date (malformed text, or an impossible day such as 2026-02-30).
 */
export function calendarDayNumber(value: string): number {
  const match = DATE_ONLY.exec(value);
  if (!match) return Number.NaN;
  const time = Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
  return new Date(time).toISOString().slice(0, 10) === value ? time / DAY_MILLISECONDS : Number.NaN;
}
