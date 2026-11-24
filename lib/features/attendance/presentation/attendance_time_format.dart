import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/time/business_time.dart';

/// Formats attendance instants on the business clock (Asia/Kolkata), never
/// the device zone, so a night shift reads the same on every device.
abstract final class AttendanceTimeFormat {
  /// The business wall-clock fields of [instant] (formatting reads fields).
  static DateTime businessWallClock(DateTime instant) =>
      instant.toUtc().add(kBusinessUtcOffset);

  /// e.g. `9:05 PM`; [placeholder] for null.
  static String time(DateTime? instant, {String placeholder = '—'}) =>
      instant == null
      ? placeholder
      : AppFormatters.formatTime(businessWallClock(instant));

  /// e.g. `Nov 7, 2026 9:05 PM`; [placeholder] for null.
  static String dateTime(DateTime? instant, {String placeholder = '—'}) =>
      instant == null
      ? placeholder
      : AppFormatters.formatDateTime(businessWallClock(instant));

  /// Whether [instant] falls on a business date after [shiftDate] (a
  /// calendar date whose fields are the shift's business date).
  static bool isAfterShiftDate(DateTime instant, DateTime shiftDate) {
    final day = BusinessTime.dateOf(instant);
    return day.isAfter(
      DateTime(shiftDate.year, shiftDate.month, shiftDate.day),
    );
  }

  /// [time] with " (next day)" when [instant] is after [shiftDate].
  static String timeOnShift(DateTime instant, DateTime shiftDate) {
    final label = time(instant);
    return isAfterShiftDate(instant, shiftDate) ? '$label (next day)' : label;
  }

  /// Hours with at most two decimals and no trailing zeros: `2h`, `1.5h`.
  static String hours(double value) {
    final fixed = value.toStringAsFixed(2);
    final trimmed = fixed.contains('.')
        ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
        : fixed;
    return '${trimmed}h';
  }
}
