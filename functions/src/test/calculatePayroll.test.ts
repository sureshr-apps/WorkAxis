import assert from "node:assert/strict";
import { test } from "node:test";
import { calculatePayroll, type PayrollCalculationInput } from "../payroll/calculatePayroll";

const fullMonth: Omit<PayrollCalculationInput, "attendance" | "basis" | "overtimeEnabled"> = {
  month: "2026-11",
  schedules: [{ effectiveFrom: "2026-11-01", dailyWorkHours: 8, weeklyDayOff: 0 }],
  compensations: [{ effectiveFrom: "2026-11-01", monthlySalary: 30_000 }],
  leaveDays: [],
  asOf: new Date("2026-11-30T18:30:00.000Z"),
};

test("hours basis caps base pay at scheduled hours and pays overtime separately at 1x", () => {
  const result = calculatePayroll({
    ...fullMonth,
    basis: "hours",
    overtimeEnabled: true,
    attendance: [{
      workDate: "2026-11-02",
      checkInAt: new Date("2026-11-02T03:30:00Z"),
      checkOutAt: new Date("2026-11-02T13:30:00Z"),
      breaks: [{ startAt: new Date("2026-11-02T07:30:00Z"), endAt: new Date("2026-11-02T08:30:00Z") }],
      status: "present",
    }],
  });
  assert.equal(result.actualHours, 9);
  assert.equal(result.payableHours, 8);
  assert.equal(result.overtimeHours, 1);
  assert.equal(result.overtimePay, 30000 / result.scheduledHours);
  assert.equal(result.grossPay, result.basePay + result.overtimePay);
});

test("overtime disabled excludes excess hours from pay", () => {
  const result = calculatePayroll({
    ...fullMonth,
    basis: "hours",
    overtimeEnabled: false,
    attendance: [{
      workDate: "2026-11-02",
      checkInAt: new Date("2026-11-02T03:30:00Z"),
      checkOutAt: new Date("2026-11-02T13:30:00Z"),
      status: "present",
    }],
  });
  assert.equal(result.overtimeHours, 2);
  assert.equal(result.overtimePay, 0);
  assert.equal(result.payableHours, 8);
});

test("workday basis pays one day for any valid punch and deduplicates sessions", () => {
  const result = calculatePayroll({
    ...fullMonth,
    basis: "workdays",
    overtimeEnabled: false,
    attendance: [
      { workDate: "2026-11-02", checkInAt: new Date("2026-11-02T03:30:00Z"), checkOutAt: new Date("2026-11-02T04:30:00Z"), status: "present" },
      { workDate: "2026-11-02", checkInAt: new Date("2026-11-02T08:00:00Z"), checkOutAt: new Date("2026-11-02T12:00:00Z"), status: "present" },
    ],
  });
  assert.equal(result.payableWorkdays, 1);
  assert.equal(result.grossPay, 30_000 / result.scheduledWorkdays);
});

test("weekly off and approved unpaid leave add no payable time", () => {
  const result = calculatePayroll({
    ...fullMonth,
    basis: "hours",
    overtimeEnabled: false,
    leaveDays: [{ date: "2026-11-03", paid: false }],
    attendance: [
      { workDate: "2026-11-01", checkInAt: new Date("2026-11-01T03:00:00Z"), checkOutAt: new Date("2026-11-01T12:00:00Z"), status: "present" },
      { workDate: "2026-11-03", checkInAt: new Date("2026-11-03T03:00:00Z"), checkOutAt: new Date("2026-11-03T12:00:00Z"), status: "present" },
    ],
  });
  assert.equal(result.payableHours, 0);
  assert.equal(result.unpaidLeaveDays, 1);
  assert.equal(result.actualHours, 0);
});

test("salary rate changes apply only to the effective calendar segment", () => {
  const result = calculatePayroll({
    ...fullMonth,
    basis: "workdays",
    overtimeEnabled: false,
    compensations: [
      { effectiveFrom: "2026-11-01", effectiveTo: "2026-11-16", monthlySalary: 30_000 },
      { effectiveFrom: "2026-11-16", monthlySalary: 60_000 },
    ],
    attendance: [
      { workDate: "2026-11-02", checkInAt: new Date("2026-11-02T03:00:00Z"), status: "present" },
      { workDate: "2026-11-16", checkInAt: new Date("2026-11-16T03:00:00Z"), status: "present" },
    ],
  });
  assert.equal(result.payableWorkdays, 2);
  assert.equal(result.grossPay, (30_000 + 60_000) / result.scheduledWorkdays);
});

test("a month before schedule or salary history is unavailable instead of being reported as zero", () => {
  const result = calculatePayroll({
    ...fullMonth,
    month: "2026-10",
    basis: "hours",
    overtimeEnabled: false,
    attendance: [],
  });
  assert.equal(result.available, false);
  assert.equal(result.unavailableReason, "noScheduledHours");
});

/** A present 9:00-17:00 IST punch on every scheduled (non-Sunday) day in [from, to]. */
function workedDays(from: number, to: number): PayrollCalculationInput["attendance"][number][] {
  const attendance: PayrollCalculationInput["attendance"][number][] = [];
  for (let day = from; day <= to; day++) {
    const date = `2026-11-${String(day).padStart(2, "0")}`;
    if (new Date(`${date}T00:00:00.000Z`).getUTCDay() === 0) continue;
    attendance.push({
      workDate: date,
      checkInAt: new Date(`${date}T03:30:00.000Z`),
      checkOutAt: new Date(`${date}T11:30:00.000Z`),
      status: "present",
    });
  }
  return attendance;
}

// November 2026 has 25 scheduled days (Sundays 1, 8, 15, 22 and 29 off).
const NOVEMBER_WORKDAYS = 25;

test("a mid-month joiner is paid only for the days after joining", () => {
  const attendance = workedDays(16, 30);
  const result = calculatePayroll({
    month: "2026-11",
    basis: "hours",
    overtimeEnabled: false,
    schedules: [{ effectiveFrom: "2026-11-15", dailyWorkHours: 8, weeklyDayOff: 0 }],
    compensations: [{ effectiveFrom: "2026-11-15", monthlySalary: 30_000 }],
    attendance,
    leaveDays: [],
    asOf: new Date("2026-12-01T00:00:00.000Z"),
  });
  assert.equal(result.available, true);
  // The salary is divided over the whole month, not just the employed part.
  assert.equal(result.scheduledWorkdays, NOVEMBER_WORKDAYS);
  assert.equal(result.outsideEmploymentDays, NOVEMBER_WORKDAYS - attendance.length);
  assert.equal(result.grossPay, 30_000 * attendance.length / NOVEMBER_WORKDAYS);
});

test("the joining date wins over earlier schedule history", () => {
  const attendance = workedDays(1, 30);
  const result = calculatePayroll({
    ...fullMonth,
    basis: "workdays",
    overtimeEnabled: false,
    attendance,
    employmentStart: "2026-11-20",
  });
  const employed = workedDays(20, 30).length;
  assert.equal(result.payableWorkdays, employed);
  assert.equal(result.grossPay, 30_000 * employed / NOVEMBER_WORKDAYS);
});

test("a mid-month leaver is paid only up to the relieving date", () => {
  const result = calculatePayroll({
    ...fullMonth,
    basis: "workdays",
    overtimeEnabled: false,
    attendance: workedDays(1, 30),
    employmentEnd: "2026-11-10",
  });
  const employed = workedDays(1, 10).length;
  assert.equal(result.payableWorkdays, employed);
  assert.equal(result.grossPay, 30_000 * employed / NOVEMBER_WORKDAYS);
});

test("a month wholly before joining is unavailable, not zero", () => {
  const result = calculatePayroll({
    ...fullMonth,
    basis: "hours",
    overtimeEnabled: false,
    attendance: [],
    employmentStart: "2026-12-01",
  });
  assert.equal(result.available, false);
  assert.equal(result.unavailableReason, "noScheduledHours");
});

test("a paid leave day is paid as a full scheduled day on either basis", () => {
  for (const basis of ["hours", "workdays"] as const) {
    const result = calculatePayroll({
      ...fullMonth,
      basis,
      overtimeEnabled: false,
      attendance: [],
      leaveDays: [
        { date: "2026-11-02", paid: true },
        { date: "2026-11-03", paid: false },
      ],
    });
    assert.equal(result.paidLeaveDays, 1, basis);
    assert.equal(result.unpaidLeaveDays, 1, basis);
    assert.equal(result.grossPay, 30_000 / NOVEMBER_WORKDAYS, basis);
    assert.equal(result.unpaidLeaveImpact, 30_000 / NOVEMBER_WORKDAYS, basis);
  }
});
