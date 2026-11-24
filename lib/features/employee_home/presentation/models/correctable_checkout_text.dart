import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/employee_home/presentation/formatting/business_time_text.dart';

/// Display text for a session whose check-out can be corrected.
extension CorrectableCheckoutText on AttendanceEntry {
  /// e.g. `Shift Nov 7` (the shift date; a night shift keeps its start day).
  String get shiftDateLabel =>
      'Shift ${AppFormatters.formatShortDate(workDate)}';

  /// e.g. `Checked in 9:00 PM`.
  String get checkInLabel => checkInAt == null
      ? 'No check-in recorded'
      : 'Checked in ${BusinessTimeText.time(checkInAt!)}';

  /// `Missing check-out` or `Late check-out at Nov 8, 9:40 AM`.
  String get checkoutProblemLabel {
    final recorded = checkOutAt;
    if (checkoutStatus == CheckoutStatus.late && recorded != null) {
      return 'Late check-out at ${BusinessTimeText.shortDateTime(recorded)}';
    }
    return 'Missing check-out';
  }
}
