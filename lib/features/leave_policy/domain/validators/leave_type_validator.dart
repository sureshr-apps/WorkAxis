import 'package:workaxis/features/leave_policy/domain/models/leave_type_input.dart';

enum LeaveTypeField { name, yearlyDays }

/// Input rules for a leave type, matching the server's `SaveLeaveType`
/// checks (the server remains authoritative).
abstract final class LeaveTypeValidator {
  static const int maxNameLength = 60;
  static const double maxYearlyDays = 366;

  /// Parses a days value typed by the user; null when it is not a number.
  static double? parseDays(String text) {
    final value = double.tryParse(text.trim());
    if (value == null || value.isNaN || value.isInfinite) return null;
    return value;
  }

  static String? name(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Enter a leave type name.';
    if (trimmed.length > maxNameLength) {
      return 'Use $maxNameLength characters or fewer.';
    }
    return null;
  }

  /// [days] is null when the typed value was not a number.
  static String? yearlyDays(double? days) {
    if (days == null) return 'Enter the days per year, for example 12 or 1.5.';
    if (days < 0 || days > maxYearlyDays) {
      return 'Enter between 0 and ${maxYearlyDays.toInt()} days.';
    }
    if ((days * 100).roundToDouble() != days * 100) {
      return 'Use at most two decimal places.';
    }
    return null;
  }

  /// Field errors of [input]; empty when it is valid.
  static Map<LeaveTypeField, String> validate(LeaveTypeInput input) {
    return {
      LeaveTypeField.name: ?name(input.name),
      LeaveTypeField.yearlyDays: ?yearlyDays(input.yearlyDays),
    };
  }
}
