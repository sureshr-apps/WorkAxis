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

class BranchPerformanceMetric {
  final String branchId;
  final String branchName;
  final double attendanceRate;
  final int activeEmployees;
  final int pendingExceptions;
  final int returnCount;

  const BranchPerformanceMetric({
    required this.branchId,
    required this.branchName,
    required this.attendanceRate,
    required this.activeEmployees,
    required this.pendingExceptions,
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

class OperationalReportSummary {
  final String period;
  final double attendanceRate;
  final double onTimeRate;
  final double totalHoursLogged;
  final int exceptionCount;
  final int returnVolume;
  final double returnRate;
  final List<DailyAttendanceMetric> dailyTrends;
  final List<BranchPerformanceMetric> branchMetrics;
  final List<CategoryReturnMetric> returnCategories;

  const OperationalReportSummary({
    required this.period,
    required this.attendanceRate,
    required this.onTimeRate,
    required this.totalHoursLogged,
    required this.exceptionCount,
    required this.returnVolume,
    required this.returnRate,
    required this.dailyTrends,
    required this.branchMetrics,
    required this.returnCategories,
  });
}
