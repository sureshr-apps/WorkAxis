/**
 * Leave ledger: decides, day by day, whether an approved leave day is paid
 * (covered by the leave type's allowance) or unpaid (deducted from salary).
 *
 * Rules (organization leave policy):
 * - Each leave type has a yearly allowance in days, accrued as 1/12 per
 *   month. Allowances are effective-dated: each month accrues at the rate in
 *   force when it began, so a change applies from the next month and never
 *   re-rates months that had started or alters a day already evaluated.
 * - In the joining year the allowance is pro-rated from the joining month.
 * - With monthly accrual (effective-dated, organization-wide) 1/12 of the
 *   yearly allowance becomes available each month and unused accrual stays
 *   available for the rest of the year. Without it the year's (pro-rated)
 *   allowance is available from the start of the year.
 * - At year end unused days lapse, unless the type's version in force on
 *   31 December carries forward; then they are added to the next year.
 * - Only scheduled working days count; selected weekly days off and days without a
 *   schedule are not leave days. Days before joining or after relieving are
 *   ignored.
 * - Days are consumed in date order. A day is paid only while at least one
 *   whole day is available, so fractional allowances round down.
 * - Unpaid types (`paid: false`) are never paid and use no allowance.
 */

export interface AllowanceVersion {
  effectiveFrom: string;
  yearlyDays: number;
  carryForward: boolean;
}

export interface LeaveTypePolicy {
  id: string;
  paid: boolean;
  allowances: readonly AllowanceVersion[];
}

export interface AccrualVersion {
  effectiveFrom: string;
  monthlyAccrual: boolean;
}

export interface LedgerSchedule {
  effectiveFrom: string;
  effectiveTo?: string | null;
  /** Recurring days off, Sunday = 0. Empty means none. */
  weeklyDaysOff: readonly number[];
}

export interface LedgerLeave {
  /** Identifies the request (a preview passes its own id). */
  id: string;
  leaveTypeId: string;
  startDate: string;
  endDate: string;
}

export interface LedgerInput {
  types: readonly LeaveTypePolicy[];
  accrual: readonly AccrualVersion[];
  schedules: readonly LedgerSchedule[];
  /** Approved leave of one member, any order. */
  leaves: readonly LedgerLeave[];
  joiningDate?: string | null;
  relievingDate?: string | null;
}

export interface LedgerDay {
  date: string;
  leaveId: string;
  leaveTypeId: string;
  paid: boolean;
}

const EPSILON = 1e-9;

/** Every counted leave day, in date order, marked paid or unpaid. */
export function leaveLedger(input: LedgerInput): LedgerDay[] {
  return walk(input).days;
}

/**
 * Whole days of [leaveTypeId] available on [date], after the approved leave
 * before that date has used its share.
 */
export function availableDays(input: LedgerInput, leaveTypeId: string, date: string): number {
  const type = input.types.find((t) => t.id === leaveTypeId);
  if (!type?.paid) return 0;
  const { days, carriedInto } = walk(input, date);
  const year = Number(date.slice(0, 4));
  const used = days.filter(
    (day) =>
      day.paid && day.leaveTypeId === leaveTypeId && day.date < date &&
      Number(day.date.slice(0, 4)) === year,
  ).length;
  const carried = carriedInto(year).get(leaveTypeId) ?? 0;
  const available = carried + accruedBy(date, type, input) - used;
  return Math.max(0, Math.floor(available + EPSILON));
}

/**
 * Walks every year from the first one that can hold a balance up to the last
 * leave day (or [until]), consuming allowance in date order.
 */
function walk(input: LedgerInput, until?: string) {
  const types = new Map(input.types.map((type) => [type.id, type]));
  const leaveDays = leaveWorkdays(input);
  const lastDate = [until, leaveDays.at(-1)?.date].filter(Boolean).sort().at(-1);
  const carriedByYear = new Map<number, Map<string, number>>();
  const days: LedgerDay[] = [];
  if (!lastDate) return { days, carriedInto: () => new Map<string, number>() };

  const firstYear = Math.min(
    input.joiningDate ? Number(input.joiningDate.slice(0, 4)) : Infinity,
    leaveDays.length ? Number(leaveDays[0].date.slice(0, 4)) : Infinity,
    Number(lastDate.slice(0, 4)),
  );
  const lastYear = Number(lastDate.slice(0, 4));
  let carried = new Map<string, number>();
  let index = 0;
  for (let year = firstYear; year <= lastYear; year++) {
    carriedByYear.set(year, carried);
    const used = new Map<string, number>();
    for (; index < leaveDays.length && leaveDays[index].date.startsWith(`${year}-`); index++) {
      const day = leaveDays[index];
      const type = types.get(day.leaveTypeId);
      let paid = false;
      if (type?.paid) {
        const available =
          (carried.get(type.id) ?? 0) + accruedBy(day.date, type, input) - (used.get(type.id) ?? 0);
        paid = available >= 1 - EPSILON;
        if (paid) used.set(type.id, (used.get(type.id) ?? 0) + 1);
      }
      days.push({ ...day, paid });
    }
    carried = carryForward(year, types, input, carried, used);
  }
  return {
    days,
    carriedInto: (year: number) => carriedByYear.get(year) ?? new Map<string, number>(),
  };
}

/** Unused days moved into the next year, for types that carry forward. */
function carryForward(
  year: number,
  types: Map<string, LeaveTypePolicy>,
  input: LedgerInput,
  carried: Map<string, number>,
  used: Map<string, number>,
): Map<string, number> {
  const yearEnd = `${year}-12-31`;
  const next = new Map<string, number>();
  for (const type of types.values()) {
    if (!type.paid || !versionAt(type.allowances, yearEnd)?.carryForward) continue;
    const unused =
      (carried.get(type.id) ?? 0) + accruedBy(yearEnd, type, input) - (used.get(type.id) ?? 0);
    if (unused > EPSILON) next.set(type.id, unused);
  }
  return next;
}

/**
 * Allowance of [type] available in [date]'s year as seen on [date]: one
 * twelfth of the yearly allowance per month from the joining month (in the
 * joining year), through [date]'s month with monthly accrual, else through
 * December.
 *
 * Each month accrues at the rate in force when it began, so an allowance
 * change never re-rates months that had already started. Months still ahead
 * of [date] (yearly availability) use the rate in force on [date]; a later
 * change therefore cannot alter a day already evaluated.
 */
function accruedBy(date: string, type: LeaveTypePolicy, input: LedgerInput): number {
  const year = Number(date.slice(0, 4));
  const month = Number(date.slice(5, 7));
  let startMonth = 1;
  if (input.joiningDate) {
    const joinYear = Number(input.joiningDate.slice(0, 4));
    if (joinYear > year) return 0;
    if (joinYear === year) startMonth = Number(input.joiningDate.slice(5, 7));
  }
  const monthly = versionAt(input.accrual, date)?.monthlyAccrual === true;
  const lastMonth = monthly ? month : 12;
  let accrued = 0;
  for (let m = startMonth; m <= lastMonth; m++) {
    const monthStart = `${year}-${String(m).padStart(2, "0")}-01`;
    const rateDate = monthStart < date ? monthStart : date;
    accrued += Math.max(0, versionAt(type.allowances, rateDate)?.yearlyDays ?? 0) / 12;
  }
  return accrued;
}

function versionAt<T extends { effectiveFrom: string }>(
  versions: readonly T[],
  date: string,
): T | undefined {
  let found: T | undefined;
  for (const version of versions) {
    if (version.effectiveFrom <= date && (!found || version.effectiveFrom >= found.effectiveFrom)) {
      found = version;
    }
  }
  return found;
}

/** Scheduled working days covered by approved leave, one entry per date. */
function leaveWorkdays(input: LedgerInput): Omit<LedgerDay, "paid">[] {
  const byDate = new Map<string, Omit<LedgerDay, "paid">>();
  const leaves = [...input.leaves].sort((a, b) =>
    a.startDate === b.startDate ? a.id.localeCompare(b.id) : a.startDate.localeCompare(b.startDate),
  );
  for (const leave of leaves) {
    for (let date = leave.startDate; date <= leave.endDate; date = nextDate(date)) {
      if (byDate.has(date)) continue;
      if (input.joiningDate && date < input.joiningDate) continue;
      if (input.relievingDate && date > input.relievingDate) continue;
      if (!isScheduledWorkday(input.schedules, date)) continue;
      byDate.set(date, { date, leaveId: leave.id, leaveTypeId: leave.leaveTypeId });
    }
  }
  return [...byDate.values()].sort((a, b) => a.date.localeCompare(b.date));
}

function isScheduledWorkday(schedules: readonly LedgerSchedule[], date: string): boolean {
  const schedule = schedules.find(
    (s) => s.effectiveFrom <= date && (!s.effectiveTo || date < s.effectiveTo),
  );
  if (!schedule) return false;
  return !schedule.weeklyDaysOff.includes(new Date(`${date}T00:00:00.000Z`).getUTCDay());
}

function nextDate(date: string): string {
  const next = new Date(`${date}T00:00:00.000Z`);
  next.setUTCDate(next.getUTCDate() + 1);
  return next.toISOString().slice(0, 10);
}
