import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { previewLeave } from "../leave/leavePreview";
import {
  availableDays,
  leaveLedger,
  type LedgerInput,
  type LedgerLeave,
  type LeaveTypePolicy,
} from "../payroll/leaveLedger";

// Sundays are the weekly day off. 2026-01-05 and 2026-02-02 are Mondays.
const annual = (yearlyDays: number, carryForward = false, effectiveFrom = "1970-01-01"): LeaveTypePolicy => ({
  id: "annual",
  paid: true,
  allowances: [{ effectiveFrom, yearlyDays, carryForward }],
});
const unpaid: LeaveTypePolicy = { id: "unpaid", paid: false, allowances: [] };

function input(over: Partial<LedgerInput> = {}): LedgerInput {
  return {
    types: [annual(2), unpaid],
    accrual: [{ effectiveFrom: "1970-01-01", monthlyAccrual: false }],
    schedules: [{ effectiveFrom: "2020-01-01", weeklyDaysOff: [0] }],
    leaves: [],
    ...over,
  };
}

let next = 0;
const leave = (startDate: string, endDate = startDate, leaveTypeId = "annual"): LedgerLeave => ({
  id: `l${next++}`,
  leaveTypeId,
  startDate,
  endDate,
});

const paidDates = (ledger: ReturnType<typeof leaveLedger>) =>
  ledger.filter((d) => d.paid).map((d) => d.date);
const unpaidDates = (ledger: ReturnType<typeof leaveLedger>) =>
  ledger.filter((d) => !d.paid).map((d) => d.date);

describe("leave ledger", () => {
  it("pays leave within the yearly allowance and deducts the rest, earliest first", () => {
    const ledger = leaveLedger(input({ leaves: [leave("2026-01-05", "2026-01-07")] }));
    assert.deepEqual(paidDates(ledger), ["2026-01-05", "2026-01-06"]);
    assert.deepEqual(unpaidDates(ledger), ["2026-01-07"]);
  });

  it("counts only scheduled working days", () => {
    // Saturday 3 Jan to Tuesday 6 Jan: Sunday the 4th is the day off.
    const ledger = leaveLedger(input({ leaves: [leave("2026-01-03", "2026-01-06")] }));
    assert.deepEqual(ledger.map((d) => d.date), ["2026-01-03", "2026-01-05", "2026-01-06"]);
    assert.deepEqual(unpaidDates(ledger), ["2026-01-06"]);
  });

  it("skips every selected weekly day off, and none when no day is off", () => {
    // Friday 2 Jan to Monday 5 Jan 2026.
    const span = [leave("2026-01-02", "2026-01-05")];
    const weekend = leaveLedger(input({
      leaves: span,
      schedules: [{ effectiveFrom: "2020-01-01", weeklyDaysOff: [0, 6] }],
    }));
    assert.deepEqual(weekend.map((d) => d.date), ["2026-01-02", "2026-01-05"]);
    const none = leaveLedger(input({
      leaves: span,
      schedules: [{ effectiveFrom: "2020-01-01", weeklyDaysOff: [] }],
    }));
    assert.equal(none.length, 4);
  });

  it("never pays an unpaid leave type", () => {
    const ledger = leaveLedger(input({ leaves: [leave("2026-01-05", "2026-01-05", "unpaid")] }));
    assert.deepEqual(unpaidDates(ledger), ["2026-01-05"]);
  });

  it("accrues monthly and carries unused accrual to later months", () => {
    const monthly = input({
      types: [annual(12)],
      accrual: [{ effectiveFrom: "1970-01-01", monthlyAccrual: true }],
      leaves: [leave("2026-01-05", "2026-01-06")],
    });
    // January has accrued one day.
    assert.deepEqual(paidDates(leaveLedger(monthly)), ["2026-01-05"]);
    // Nothing taken in January: two days are available in February.
    const later = leaveLedger({ ...monthly, leaves: [leave("2026-02-02", "2026-02-03")] });
    assert.deepEqual(paidDates(later), ["2026-02-02", "2026-02-03"]);
  });

  it("rounds a fractional monthly accrual down to whole days", () => {
    const monthly = input({
      types: [annual(2)],
      accrual: [{ effectiveFrom: "1970-01-01", monthlyAccrual: true }],
    });
    // 2 a year is 1/6 a month: no whole day in January, one by June.
    assert.deepEqual(paidDates(leaveLedger({ ...monthly, leaves: [leave("2026-01-05")] })), []);
    assert.deepEqual(paidDates(leaveLedger({ ...monthly, leaves: [leave("2026-06-01")] })), ["2026-06-01"]);
  });

  it("pro-rates the allowance from the joining month", () => {
    // Joined in July: 6 of 12 months, so 6 of 12 days.
    const joined = input({ types: [annual(12)], joiningDate: "2026-07-01" });
    assert.equal(availableDays(joined, "annual", "2026-07-06"), 6);
    const monthly = { ...joined, accrual: [{ effectiveFrom: "1970-01-01", monthlyAccrual: true }] };
    assert.equal(availableDays(monthly, "annual", "2026-07-06"), 1);
    assert.equal(availableDays(monthly, "annual", "2026-09-07"), 3);
  });

  it("ignores leave before joining and after relieving", () => {
    const ledger = leaveLedger(input({
      joiningDate: "2026-01-06",
      relievingDate: "2026-01-07",
      leaves: [leave("2026-01-05", "2026-01-08")],
    }));
    assert.deepEqual(ledger.map((d) => d.date), ["2026-01-06", "2026-01-07"]);
  });

  it("lapses unused days at year end unless the type carries forward", () => {
    const nextYear = [leave("2027-01-04", "2027-01-07")];
    assert.equal(paidDates(leaveLedger(input({ joiningDate: "2026-01-01", leaves: nextYear }))).length, 2);
    const carrying = input({ types: [annual(2, true)], joiningDate: "2026-01-01", leaves: nextYear });
    assert.equal(paidDates(leaveLedger(carrying)).length, 4);
    assert.equal(availableDays(carrying, "annual", "2027-01-04"), 4);
  });

  it("carries only what was left after leave taken", () => {
    const carrying = input({
      types: [annual(2, true)],
      joiningDate: "2026-01-01",
      leaves: [leave("2026-03-02"), leave("2027-01-04", "2027-01-08")],
    });
    // 2026: one of two used, one carried; 2027: 2 + 1 = 3 paid.
    assert.equal(paidDates(leaveLedger(carrying)).filter((d) => d.startsWith("2027")).length, 3);
  });

  it("applies an allowance change only from its effective date", () => {
    const changed = input({
      types: [{
        id: "annual",
        paid: true,
        allowances: [
          { effectiveFrom: "1970-01-01", yearlyDays: 1, carryForward: false },
          { effectiveFrom: "2026-06-01", yearlyDays: 3, carryForward: false },
        ],
      }],
      leaves: [leave("2026-03-02", "2026-03-03"), leave("2026-06-01", "2026-06-03")],
    });
    const ledger = leaveLedger(changed);
    // March: allowance 1, so one paid. From June: January-May keep the old
    // rate (5/12) and June-December the new one (21/12), 2 1/6 days with one
    // used, so one more whole day is paid.
    assert.deepEqual(paidDates(ledger), ["2026-03-02", "2026-06-01"]);
    // The March days are decided exactly as before the change.
    const before = leaveLedger({ ...changed, types: [annual(1)] }).filter((d) => d.date < "2026-06-01");
    assert.deepEqual(ledger.filter((d) => d.date < "2026-06-01"), before);
  });

  it("keeps months already accrued at the old rate when the allowance rises", () => {
    // Monthly accrual, 12 a year until June, then 24: January-May accrue
    // 1 a month and June 2, so 7 days are available in June, not 12.
    const raised = input({
      types: [{
        id: "annual",
        paid: true,
        allowances: [
          { effectiveFrom: "1970-01-01", yearlyDays: 12, carryForward: false },
          { effectiveFrom: "2026-06-01", yearlyDays: 24, carryForward: false },
        ],
      }],
      accrual: [{ effectiveFrom: "1970-01-01", monthlyAccrual: true }],
    });
    assert.equal(availableDays(raised, "annual", "2026-06-15"), 7);
    assert.equal(availableDays(raised, "annual", "2026-07-15"), 9);
    // A change made mid-month takes effect from the next month.
    const midMonth = {
      ...raised,
      types: [{
        ...raised.types[0],
        allowances: [
          { effectiveFrom: "1970-01-01", yearlyDays: 12, carryForward: false },
          { effectiveFrom: "2026-06-15", yearlyDays: 24, carryForward: false },
        ],
      }],
    };
    assert.equal(availableDays(midMonth, "annual", "2026-06-20"), 6);
    assert.equal(availableDays(midMonth, "annual", "2026-07-01"), 8);
  });

  it("gives only the remaining months the new rate with yearly availability", () => {
    // 12 a year, raised to 24 from July: 6 months at 1 plus 6 at 2 = 18.
    const raised = input({
      types: [{
        id: "annual",
        paid: true,
        allowances: [
          { effectiveFrom: "1970-01-01", yearlyDays: 12, carryForward: false },
          { effectiveFrom: "2026-07-01", yearlyDays: 24, carryForward: false },
        ],
      }],
    });
    assert.equal(availableDays(raised, "annual", "2026-03-02"), 12);
    assert.equal(availableDays(raised, "annual", "2026-07-06"), 18);
  });

  it("applies the monthly-accrual flag only from its effective date", () => {
    const switched = input({
      types: [annual(12)],
      accrual: [
        { effectiveFrom: "1970-01-01", monthlyAccrual: false },
        { effectiveFrom: "2026-03-01", monthlyAccrual: true },
      ],
      leaves: [leave("2026-01-05", "2026-01-09"), leave("2026-03-02", "2026-03-06")],
    });
    // January: the full 12 are available; March: 3 accrued, 5 already used.
    const ledger = leaveLedger(switched);
    assert.equal(paidDates(ledger).filter((d) => d.startsWith("2026-01")).length, 5);
    assert.equal(paidDates(ledger).filter((d) => d.startsWith("2026-03")).length, 0);
  });
});

describe("leave preview", () => {
  it("reports available, paid and unpaid days for a draft", () => {
    const preview = previewLeave(input({ leaves: [leave("2026-01-05")] }), {
      id: "preview",
      leaveTypeId: "annual",
      startDate: "2026-02-02",
      endDate: "2026-02-04",
    });
    assert.deepEqual(preview, { availableDays: 1, workdays: 3, paidDays: 1, unpaidDays: 2 });
  });

  it("does not count a request against itself when it is being edited", () => {
    const own = leave("2026-01-05", "2026-01-06");
    const preview = previewLeave(input({ leaves: [own] }), { ...own, endDate: "2026-01-07" });
    assert.deepEqual(preview, { availableDays: 2, workdays: 3, paidDays: 2, unpaidDays: 1 });
  });
});
