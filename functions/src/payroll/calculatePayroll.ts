export type PayBasis = "hours" | "workdays";

export interface ScheduleVersion {
  effectiveFrom: string;
  effectiveTo?: string | null;
  dailyWorkHours: number;
  weeklyDayOff: number;
}

export interface CompensationVersion {
  effectiveFrom: string;
  effectiveTo?: string | null;
  monthlySalary: number;
}

export interface PayrollBreak {
  startAt: Date;
  endAt?: Date | null;
}

export interface PayrollAttendanceSession {
  workDate: string;
  checkInAt?: Date | null;
  checkOutAt?: Date | null;
  breaks?: readonly PayrollBreak[];
  status?: string;
}

export interface ApprovedLeaveRange {
  startDate: string;
  endDate: string;
}

export interface PayrollCalculationInput {
  month: string;
  basis: PayBasis;
  overtimeEnabled: boolean;
  schedules: readonly ScheduleVersion[];
  compensations: readonly CompensationVersion[];
  attendance: readonly PayrollAttendanceSession[];
  approvedLeaves: readonly ApprovedLeaveRange[];
  asOf?: Date;
}

export interface PayrollCalculation {
  available: boolean;
  unavailableReason?: "scheduleMissing" | "salaryMissing" | "noScheduledHours";
  scheduledHours: number;
  payableHours: number;
  actualHours: number;
  scheduledWorkdays: number;
  payableWorkdays: number;
  unpaidLeaveDays: number;
  unpaidLeaveImpact: number;
  overtimeHours: number;
  overtimePay: number;
  basePay: number;
  grossPay: number;
}

interface DayRecord {
  date: string;
  scheduled: boolean;
  scheduledHours: number;
  unpaidLeave: boolean;
  hasValidPunch: boolean;
  actualHours: number;
  salary?: number;
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const HOUR_MS = 60 * 60 * 1000;

/** Calculates gross pay for a calendar month using effective-dated history. */
export function calculatePayroll(input: PayrollCalculationInput): PayrollCalculation {
  if (!/^\d{4}-\d{2}$/.test(input.month)) {
    throw new Error("month must use YYYY-MM format.");
  }
  const [year, month] = input.month.split("-").map(Number);
  const days: DayRecord[] = [];
  const attendanceByDate = groupAttendance(input.attendance, input.asOf ?? new Date());
  const employmentStart = [
    ...input.schedules.map((version) => version.effectiveFrom),
    ...input.compensations.map((version) => version.effectiveFrom),
  ].sort()[0];
  let missingSchedule = false;
  let missingSalary = false;

  for (let d = 1; d <= new Date(Date.UTC(year, month, 0)).getUTCDate(); d++) {
    const date = `${input.month}-${String(d).padStart(2, "0")}`;
    if (employmentStart && date < employmentStart) {
      days.push({
        date,
        scheduled: false,
        scheduledHours: 0,
        unpaidLeave: false,
        hasValidPunch: false,
        actualHours: 0,
      });
      continue;
    }
    const schedule = effectiveAt(input.schedules, date);
    const compensation = effectiveAt(input.compensations, date);
    if (!schedule) missingSchedule = true;
    if (!compensation) missingSalary = true;
    const weekday = new Date(`${date}T00:00:00.000Z`).getUTCDay();
    const scheduled = schedule !== undefined && weekday !== schedule.weeklyDayOff;
    const unpaidLeave = input.approvedLeaves.some(
      (leave) => leave.startDate <= date && date <= leave.endDate,
    );
    const sessions = attendanceByDate.get(date) ?? [];
    days.push({
      date,
      scheduled,
      scheduledHours: scheduled ? schedule!.dailyWorkHours : 0,
      unpaidLeave,
      hasValidPunch: sessions.some((session) => session.hasValidPunch),
      actualHours: sessions.reduce((sum, session) => sum + session.hours, 0),
      salary: compensation?.monthlySalary,
    });
  }

  const scheduledDays = days.filter((d) => d.scheduled);
  const scheduledHours = scheduledDays.reduce((sum, d) => sum + d.scheduledHours, 0);
  const scheduledWorkdays = scheduledDays.length;
  if (missingSchedule) {
    return emptyCalculation("scheduleMissing", scheduledHours, scheduledWorkdays);
  }
  if (missingSalary) {
    return emptyCalculation("salaryMissing", scheduledHours, scheduledWorkdays);
  }
  if (scheduledHours <= 0 || scheduledWorkdays <= 0) {
    return emptyCalculation("noScheduledHours", scheduledHours, scheduledWorkdays);
  }

  let payableHours = 0;
  let actualHours = 0;
  let payableWorkdays = 0;
  let unpaidLeaveDays = 0;
  let unpaidLeaveImpact = 0;
  let overtimeHours = 0;
  let overtimePay = 0;
  let basePay = 0;

  for (const day of scheduledDays) {
    const salary = day.salary ?? 0;
    const attendedHours = day.unpaidLeave ? 0 : day.actualHours;
    const dayBaseHours = Math.min(attendedHours, day.scheduledHours);
    const dayOvertimeHours = Math.max(0, attendedHours - day.scheduledHours);
    const attendedDay = !day.unpaidLeave && day.hasValidPunch;

    actualHours += day.unpaidLeave ? 0 : day.actualHours;
    if (day.unpaidLeave) {
      unpaidLeaveDays++;
      unpaidLeaveImpact += input.basis === "hours"
        ? salary * day.scheduledHours / scheduledHours
        : salary / scheduledWorkdays;
      continue;
    }

    if (input.basis === "hours") {
      payableHours += dayBaseHours;
      basePay += salary * dayBaseHours / scheduledHours;
    } else if (attendedDay) {
      payableWorkdays++;
      basePay += salary / scheduledWorkdays;
    }

    overtimeHours += dayOvertimeHours;
    if (input.overtimeEnabled) {
      overtimePay += salary * dayOvertimeHours / scheduledHours;
    }
  }

  basePay = roundCurrency(basePay);
  overtimePay = roundCurrency(overtimePay);
  return {
    available: true,
    scheduledHours: roundHours(scheduledHours),
    payableHours: roundHours(payableHours),
    actualHours: roundHours(actualHours),
    scheduledWorkdays,
    payableWorkdays,
    unpaidLeaveDays,
    unpaidLeaveImpact: roundCurrency(unpaidLeaveImpact),
    overtimeHours: roundHours(overtimeHours),
    overtimePay,
    basePay,
    grossPay: roundCurrency(basePay + overtimePay),
  };
}

function emptyCalculation(
  unavailableReason: PayrollCalculation["unavailableReason"],
  scheduledHours: number,
  scheduledWorkdays: number,
): PayrollCalculation {
  return {
    available: false,
    unavailableReason,
    scheduledHours: roundHours(scheduledHours),
    payableHours: 0,
    actualHours: 0,
    scheduledWorkdays,
    payableWorkdays: 0,
    unpaidLeaveDays: 0,
    unpaidLeaveImpact: 0,
    overtimeHours: 0,
    overtimePay: 0,
    basePay: 0,
    grossPay: 0,
  };
}

function effectiveAt<T extends { effectiveFrom: string; effectiveTo?: string | null }>(
  versions: readonly T[],
  date: string,
): T | undefined {
  return versions.find(
    (v) => v.effectiveFrom <= date && (!v.effectiveTo || date < v.effectiveTo),
  );
}

function groupAttendance(
  sessions: readonly PayrollAttendanceSession[],
  asOf: Date,
): Map<string, { hasValidPunch: boolean; hours: number }[]> {
  const grouped = new Map<string, { hasValidPunch: boolean; hours: number }[]>();
  for (const session of sessions) {
    if (!DATE_RE.test(session.workDate) || !session.checkInAt) continue;
    const hasValidPunch = session.status !== "absent" && session.status !== "incomplete";
    const end = session.checkOutAt ?? (sameDate(session.workDate, asOf) ? asOf : null);
    let ms = end ? Math.max(0, end.getTime() - session.checkInAt.getTime()) : 0;
    for (const pause of session.breaks ?? []) {
      const pauseEnd = pause.endAt ?? end;
      if (pauseEnd) {
        const clampedEnd = new Date(Math.min(pauseEnd.getTime(), end?.getTime() ?? pauseEnd.getTime()));
        ms -= Math.max(0, clampedEnd.getTime() - pause.startAt.getTime());
      }
    }
    const item = { hasValidPunch, hours: Math.max(0, ms) / HOUR_MS };
    const list = grouped.get(session.workDate) ?? [];
    list.push(item);
    grouped.set(session.workDate, list);
  }
  return grouped;
}

function sameDate(date: string, instant: Date): boolean {
  const utc = new Date(instant.getTime() + 5.5 * HOUR_MS);
  return date === dateString(utc);
}

function dateString(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function roundHours(value: number): number {
  return Math.round(value * 100) / 100;
}

function roundCurrency(value: number): number {
  return Math.round(value * 100) / 100;
}
