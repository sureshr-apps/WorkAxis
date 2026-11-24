import 'package:workaxis/features/attendance/presentation/attendance_time_format.dart';

/// Parses the overtime hours a manager approves: more than 0, at most the
/// potential hours, with no more than two decimals (the server's precision).
abstract final class OvertimeHoursInput {
  static final RegExp _pattern = RegExp(r'^\d+(\.\d{1,2})?$');

  /// The text a field starts with: the potential hours, two decimals at most.
  static String initialText(double potentialHours) =>
      AttendanceTimeFormat.hours(potentialHours).replaceFirst('h', '');

  /// An error message for [text], or null when it is valid.
  static String? validate(String text, double potentialHours) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Enter the hours to approve.';
    if (!_pattern.hasMatch(trimmed)) {
      return 'Use a number with up to 2 decimals, e.g. 1.5.';
    }
    final value = double.parse(trimmed);
    if (value <= 0) return 'Approve more than 0 hours, or reject instead.';
    if (value > potentialHours + 1e-9) {
      return 'At most ${AttendanceTimeFormat.hours(potentialHours)} '
          '(the potential overtime).';
    }
    return null;
  }

  /// The hours in [text]; null when [validate] reports an error.
  static double? parse(String text, double potentialHours) =>
      validate(text, potentialHours) == null ? double.parse(text.trim()) : null;
}
