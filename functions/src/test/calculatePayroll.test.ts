import assert from "node:assert/strict";
import { test } from "node:test";
import { calculatePayroll, type PayrollCalculationInput } from "../payroll/calculatePayroll";

const fullMonth: Omit<PayrollCalculationInput, "attendance" | "basis" | "overtimeEnabled"> = {
  month: "2026-11",
  schedules: [{ effectiveFrom: "2026-11-01", dailyWorkHours: 8, weeklyDayOff: 0 }],
  compensations: [{ effectiveFrom: "2026-11-01", monthlySalary: 30_000 }],
  approvedLeaves: [],
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
    approvedLeaves: [{ startDate: "2026-11-03", endDate: "2026-11-03" }],
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

test("a mid-month employment start excludes pre-employment days from the pay period", () => {
  const schedules = [{ effectiveFrom: "2026-11-15", dailyWorkHours: 8, weeklyDayOff: 0 }];
  const compensations = [{ effectiveFrom: "2026-11-15", monthlySalary: 30_000 }];
  const attendance: PayrollCalculationInput["attendance"][number][] = [];
  for (let day = 16; day <= 30; day++) {
    const date = `2026-11-${String(day).padStart(2, "0")}`;
    if (new Date(`${date}T00:00:00.000Z`).getUTCDay() === 0) continue;
    attendance.push({
      workDate: date,
      checkInAt: new Date(`${date}T03:30:00.000Z`),
      checkOutAt: new Date(`${date}T11:30:00.000Z`),
      status: "present",
    });
  }
  const result = calculatePayroll({
    month: "2026-11",
    basis: "hours",
    overtimeEnabled: false,
    schedules,
    compensations,
    attendance,
    approvedLeaves: [],
    asOf: new Date("2026-12-01T00:00:00.000Z"),
  });
  assert.equal(result.available, true);
  assert.equal(result.scheduledWorkdays, attendance.length);
  assert.equal(result.grossPay, 30_000);
});
