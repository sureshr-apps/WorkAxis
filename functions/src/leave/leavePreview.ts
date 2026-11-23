import { availableDays, leaveLedger, type LedgerInput } from "../payroll/leaveLedger";

export interface LeavePreview {
  /** Whole days of the type available on the start date. */
  availableDays: number;
  /** Scheduled working days the request covers. */
  workdays: number;
  /** Of those, days the allowance covers (paid). */
  paidDays: number;
  /** Days beyond the allowance (deducted from salary). */
  unpaidDays: number;
}

/**
 * How a leave request of [leaveTypeId] from [startDate] to [endDate] would be
 * paid if approved now, given the member's already approved leave in [input].
 */
export function previewLeave(
  input: LedgerInput,
  request: { id: string; leaveTypeId: string; startDate: string; endDate: string },
): LeavePreview {
  const others = input.leaves.filter((leave) => leave.id !== request.id);
  const base = { ...input, leaves: others };
  const days = leaveLedger({ ...base, leaves: [...others, request] }).filter(
    (day) => day.leaveId === request.id,
  );
  const paidDays = days.filter((day) => day.paid).length;
  return {
    availableDays: availableDays(base, request.leaveTypeId, request.startDate),
    workdays: days.length,
    paidDays,
    unpaidDays: days.length - paidDays,
  };
}
