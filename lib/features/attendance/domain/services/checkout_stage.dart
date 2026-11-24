import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// Where a session stands relative to its scheduled end, as of a moment.
enum CheckoutStage {
  /// Checked out (or corrected).
  checkedOut,

  /// Open, before the reminder time (or unscheduled and not expired).
  onShift,

  /// Open, the shift ended and the reminder time passed.
  reminder,

  /// Open past the overtime allowance: flagged for the manager.
  overdue,

  /// Closed by the system without a check-out; needs a correction.
  missing,
}

extension CheckoutStageOf on AttendanceEntry {
  /// The stage at [now]. Server flags win; the stored deadlines let the app
  /// show a reminder before the next server sweep runs.
  CheckoutStage checkoutStageAt(DateTime now) {
    if (checkoutStatus == CheckoutStatus.missing || sessionClosedAt != null) {
      return checkOutAt == null
          ? CheckoutStage.missing
          : CheckoutStage.checkedOut;
    }
    if (checkOutAt != null || checkInAt == null) {
      return CheckoutStage.checkedOut;
    }
    if (checkoutStatus == CheckoutStatus.overdue ||
        _reached(checkoutOverdueAt, now)) {
      return CheckoutStage.overdue;
    }
    if (_reached(checkoutReminderAt, now)) return CheckoutStage.reminder;
    return CheckoutStage.onShift;
  }

  /// Whether the employee may ask to correct this session's check-out.
  bool get canRequestCheckoutCorrection =>
      (checkoutStatus == CheckoutStatus.missing ||
          checkoutStatus == CheckoutStatus.late) &&
      correctionStatus != CorrectionStatus.pending;

  /// Whether a manager has overtime to decide on this session.
  bool get hasPendingOvertime =>
      overtimeStatus == OvertimeStatus.pending && potentialOvertimeHours > 0;
}

bool _reached(DateTime? at, DateTime now) => at != null && !now.isBefore(at);
