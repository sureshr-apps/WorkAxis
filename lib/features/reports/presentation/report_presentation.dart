import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';

/// Display rules for report figures. Unavailable (null) metrics render as an
/// em dash and are never estimated.
abstract final class ReportFormat {
  static const String unavailable = '—';

  static String percent(double? value) =>
      value == null ? unavailable : '$value%';

  static String hours(double? value) =>
      value == null ? unavailable : '${value.toInt()}h';

  static String count(int? value) =>
      value == null ? unavailable : value.toString();
}

/// Presentation rules for one branch row of the report.
extension BranchPerformancePresentation on BranchPerformanceMetric {
  /// Attendance rate (percent) at or above which a branch is "Optimal".
  static const double optimalAttendanceRate = 95;

  bool get isOptimal =>
      attendanceRate != null && attendanceRate! >= optimalAttendanceRate;

  String get statusLabel =>
      attendanceRate == null ? 'No data' : (isOptimal ? 'Optimal' : 'Review');

  StatusType get statusType =>
      isOptimal ? StatusType.active : StatusType.pending;

  String get headcountLabel => activeEmployees == null
      ? 'Headcount not available'
      : '$activeEmployees active workforce members';

  String get exceptionsLabel => pendingExceptions == null
      ? ReportFormat.unavailable
      : '$pendingExceptions pending';

  bool get hasPendingExceptions => (pendingExceptions ?? 0) > 0;
}
