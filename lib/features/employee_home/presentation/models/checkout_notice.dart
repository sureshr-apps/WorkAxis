import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/services/checkout_stage.dart';
import 'package:workaxis/features/employee_home/presentation/formatting/business_time_text.dart';

/// In-app check-out reminder for an open session whose shift has ended.
/// Reminders are shown only in the app (there are no push notifications).
class CheckoutNotice {
  const CheckoutNotice._({
    required this.isOverdue,
    required this.title,
    required this.message,
  });

  /// Past the overtime allowance: flagged for the manager to review.
  final bool isOverdue;
  final String title;
  final String message;

  /// The notice for [entry] at [now], or null while the shift is running, the
  /// session is closed, or there is no open session.
  static CheckoutNotice? of(AttendanceEntry? entry, DateTime now) {
    if (entry == null || !entry.isOpen) return null;
    final end = entry.scheduledEndAt;
    final endedAt = end == null ? null : BusinessTimeText.time(end);
    switch (entry.checkoutStageAt(now)) {
      case CheckoutStage.reminder:
        return CheckoutNotice._(
          isOverdue: false,
          title: 'Shift ended',
          message: endedAt == null
              ? 'Your shift has ended. Check out when you leave.'
              : 'Your shift ended at $endedAt. Check out when you leave.',
        );
      case CheckoutStage.overdue:
        return CheckoutNotice._(
          isOverdue: true,
          title: 'Check-out overdue',
          message:
              '${endedAt == null ? 'Your shift has ended' : 'Your shift ended at $endedAt'} '
              'and no check-out is recorded. Your manager has been notified '
              'and will review this session. Check out now if you have left.',
        );
      case CheckoutStage.checkedOut:
      case CheckoutStage.onShift:
      case CheckoutStage.missing:
        return null;
    }
  }
}
