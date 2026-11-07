import 'package:workaxis/features/reports/domain/models/report_period.dart';

class DailyAttendanceMetric {
  final String dayName;
  final double onTimePercent;
  final double latePercent;
  final double absentPercent;

  const DailyAttendanceMetric({
    required this.dayName,
    required this.onTimePercent,
    required this.latePercent,
    required this.absentPercent,
  });
}

/// Per-branch figures. Attendance-derived fields are null when the backend
/// does not provide them (there is no shift schedule or exception tracking
/// yet); they are never estimated.
class BranchPerformanceMetric {
  final String branchId;
  final String branchName;
  final double? attendanceRate;
  final int? activeEmployees;
  final int? pendingExceptions;
  final int returnCount;

  const BranchPerformanceMetric({
    required this.branchId,
    required this.branchName,
    this.attendanceRate,
    this.activeEmployees,
    this.pendingExceptions,
    required this.returnCount,
  });
}

class CategoryReturnMetric {
  final String categoryName;
  final int count;
  final double percentage;

  const CategoryReturnMetric({
    required this.categoryName,
    required this.count,
    required this.percentage,
  });
}

/// Operational report. Nullable metrics are unavailable from the backend and
/// must be rendered as "not available", never as zero.
class OperationalReportSummary {
  final ReportPeriod period;
  final double? attendanceRate;
  final double? onTimeRate;
  final double? totalHoursLogged;
  final int? exceptionCount;
  final int returnVolume;
  final double? returnRate;

  /// Whether [returnVolume] and branch return counts only cover [period].
  /// False when the backend can only count all returns to date.
  final bool returnCountsCoverPeriod;
  final List<DailyAttendanceMetric> dailyTrends;
  final List<BranchPerformanceMetric> branchMetrics;
  final List<CategoryReturnMetric> returnCategories;

  const OperationalReportSummary({
    required this.period,
    this.attendanceRate,
    this.onTimeRate,
    this.totalHoursLogged,
    this.exceptionCount,
    required this.returnVolume,
    this.returnRate,
    this.returnCountsCoverPeriod = true,
    this.dailyTrends = const [],
    required this.branchMetrics,
    this.returnCategories = const [],
  });
}
