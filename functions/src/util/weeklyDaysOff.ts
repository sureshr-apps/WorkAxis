import { invalid } from "../errors";

/**
 * Validates a list of recurring weekly days off (0 = Sunday ... 6 = Saturday)
 * and returns it de-duplicated and sorted. An empty list means no day off.
 * Undefined stays undefined so callers decide whether the field is required.
 */
export function parseWeeklyDaysOff(bag: Record<string, unknown>): number[] | undefined {
  if (bag.weeklyDayOff !== undefined) {
    // The single weeklyDayOff field was replaced; older app builds still send it.
    throw invalid("This app version is out of date. Update the app to set weekly days off.");
  }
  const value = bag.weeklyDaysOff;
  if (value === undefined) return undefined;
  if (!Array.isArray(value) || value.some((day) =>
    typeof day !== "number" || !Number.isInteger(day) || day < 0 || day > 6
  )) {
    throw invalid("weeklyDaysOff must contain weekdays from 0 (Sunday) through 6 (Saturday).");
  }
  return [...new Set(value as number[])].sort((a, b) => a - b);
}

/** Days off read from a smallint[] column, normalized. */
export function weeklyDaysOffFrom(value: readonly (number | string)[] | null | undefined): number[] {
  return [...new Set((value ?? []).map(Number))].sort((a, b) => a - b);
}
