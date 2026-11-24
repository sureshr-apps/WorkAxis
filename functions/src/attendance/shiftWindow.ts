import { invalid, precondition } from "../errors";
import { workDateStart, workDateString } from "../time/workDate";

const MINUTE_MS = 60_000;
const DAY_MS = 24 * 60 * MINUTE_MS;

/** A schedule version as stored in employee_schedule_history. */
export interface ScheduleSpan {
  effectiveFrom: string;
  effectiveTo?: string | null;
  shiftHours: string;
  dailyWorkHours: number;
  weeklyDaysOff: readonly number[];
}

/** One scheduled shift: it belongs to [shiftDate] even when it ends the next day. */
export interface ShiftWindow {
  shiftDate: string;
  startAt: Date;
  endAt: Date;
  scheduledHours: number;
}

/** Where a check-in belongs: its shift date and, when scheduled, the shift. */
export interface ResolvedShift {
  shiftDate: string;
  window: ShiftWindow | null;
}

/**
 * Start (minutes after midnight) and length of a shift such as
 * "09:00 PM - 05:00 AM". An end at or before the start crosses midnight.
 */
export function parseShiftHours(value: string): { startMinutes: number; durationMinutes: number } {
  const match = value.match(/^\s*(\d{1,2}):(\d{2})\s*(AM|PM)\s*-\s*(\d{1,2}):(\d{2})\s*(AM|PM)\s*$/i);
  if (!match) throw invalid("Shift must use a start and end time such as 09:00 AM - 05:00 PM.");
  const [, startHour, startMinute, startMeridiem, endHour, endMinute, endMeridiem] = match;
  const minutes = (hourText: string, minuteText: string, meridiem: string): number => {
    const hour = Number(hourText);
    const minute = Number(minuteText);
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) throw invalid("Shift time is invalid.");
    return ((hour % 12) + (meridiem.toUpperCase() === "PM" ? 12 : 0)) * 60 + minute;
  };
  const start = minutes(startHour, startMinute, startMeridiem);
  let end = minutes(endHour, endMinute, endMeridiem);
  if (end <= start) end += 24 * 60;
  return { startMinutes: start, durationMinutes: end - start };
}

/** The version in force on [date], if any. */
export function scheduleOn(versions: readonly ScheduleSpan[], date: string): ScheduleSpan | undefined {
  return versions
    .filter((v) => v.effectiveFrom <= date && (!v.effectiveTo || date < v.effectiveTo))
    .sort((a, b) => b.effectiveFrom.localeCompare(a.effectiveFrom))[0];
}

/** The shift scheduled on [date], or null on a day off or without a schedule. */
export function shiftOn(versions: readonly ScheduleSpan[], date: string): ShiftWindow | null {
  const version = scheduleOn(versions, date);
  if (!version || version.weeklyDaysOff.includes(weekday(date))) return null;
  const { startMinutes, durationMinutes } = parseShiftHours(version.shiftHours);
  const startAt = new Date(workDateStart(date).getTime() + startMinutes * MINUTE_MS);
  return {
    shiftDate: date,
    startAt,
    endAt: new Date(startAt.getTime() + durationMinutes * MINUTE_MS),
    scheduledHours: Number(version.dailyWorkHours),
  };
}

/**
 * Decides which shift a check-in belongs to. A check-in counts toward a shift
 * from [earlyMinutes] before its start until its scheduled end, so a 9 PM to
 * 5 AM shift stays on the day it started, even for a late check-in after
 * midnight. When several shifts qualify the one starting nearest wins. A
 * check-in outside every window belongs to its calendar date; it is refused
 * when that date is a weekly day off (without any schedule Sunday is off).
 */
export function resolveShift(
  checkInAt: Date,
  versions: readonly ScheduleSpan[],
  earlyMinutes: number,
): ResolvedShift {
  const calendarDate = workDateString(checkInAt);
  const at = checkInAt.getTime();
  const candidates = [-1, 0, 1]
    .map((offset) => shiftOn(versions, addDays(calendarDate, offset)))
    .filter((window): window is ShiftWindow =>
      window !== null &&
      at >= window.startAt.getTime() - earlyMinutes * MINUTE_MS &&
      at <= window.endAt.getTime(),
    )
    .sort((a, b) =>
      Math.abs(a.startAt.getTime() - at) - Math.abs(b.startAt.getTime() - at),
    );
  if (candidates.length) return { shiftDate: candidates[0].shiftDate, window: candidates[0] };

  const version = scheduleOn(versions, calendarDate);
  const daysOff = version ? version.weeklyDaysOff : [0];
  if (daysOff.includes(weekday(calendarDate))) {
    throw precondition("Attendance punches are not available on your weekly day off.");
  }
  return { shiftDate: calendarDate, window: shiftOn(versions, calendarDate) };
}

/** `YYYY-MM-DD` shifted by whole days. */
export function addDays(date: string, days: number): string {
  return new Date(Date.parse(`${date}T00:00:00.000Z`) + days * DAY_MS).toISOString().slice(0, 10);
}

function weekday(date: string): number {
  return new Date(`${date}T00:00:00.000Z`).getUTCDay();
}
