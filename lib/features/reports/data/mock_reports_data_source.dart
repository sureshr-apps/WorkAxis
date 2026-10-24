import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';

class MockReportsDataSource {
  OperationalReportSummary getSummary({
    required bool isBranchManager,
    String? branchId,
    String period = 'This Week',
  }) {
    if (isBranchManager) {
      return OperationalReportSummary(
        period: period,
        attendanceRate: 97.2,
        onTimeRate: 94.5,
        totalHoursLogged: 428.0,
        exceptionCount: 3,
        returnVolume: 11,
        returnRate: 0.9,
        dailyTrends: const [
          DailyAttendanceMetric(dayName: 'Mon', onTimePercent: 96, latePercent: 4, absentPercent: 0),
          DailyAttendanceMetric(dayName: 'Tue', onTimePercent: 92, latePercent: 8, absentPercent: 0),
          DailyAttendanceMetric(dayName: 'Wed', onTimePercent: 95, latePercent: 5, absentPercent: 0),
          DailyAttendanceMetric(dayName: 'Thu', onTimePercent: 97, latePercent: 3, absentPercent: 0),
          DailyAttendanceMetric(dayName: 'Fri', onTimePercent: 93, latePercent: 4, absentPercent: 3),
          DailyAttendanceMetric(dayName: 'Sat', onTimePercent: 98, latePercent: 2, absentPercent: 0),
          DailyAttendanceMetric(dayName: 'Sun', onTimePercent: 94, latePercent: 6, absentPercent: 0),
        ],
        branchMetrics: [
          BranchPerformanceMetric(
            branchId: branchId ?? 'branch-dt-01',
            branchName: 'Downtown Flagship',
            attendanceRate: 97.2,
            activeEmployees: 14,
            pendingExceptions: 3,
            returnCount: 11,
          ),
        ],
        returnCategories: const [
          CategoryReturnMetric(categoryName: 'Damaged Products', count: 5, percentage: 45.5),
          CategoryReturnMetric(categoryName: 'Expired Stock', count: 4, percentage: 36.4),
          CategoryReturnMetric(categoryName: 'Wrong Item Supplied', count: 1, percentage: 9.1),
          CategoryReturnMetric(categoryName: 'Customer Returned', count: 1, percentage: 9.0),
        ],
      );
    }

    return OperationalReportSummary(
      period: period,
      attendanceRate: 95.8,
      onTimeRate: 91.4,
      totalHoursLogged: 1684.0,
      exceptionCount: 12,
      returnVolume: 42,
      returnRate: 1.4,
      dailyTrends: const [
        DailyAttendanceMetric(dayName: 'Mon', onTimePercent: 94, latePercent: 4, absentPercent: 2),
        DailyAttendanceMetric(dayName: 'Tue', onTimePercent: 91, latePercent: 6, absentPercent: 3),
        DailyAttendanceMetric(dayName: 'Wed', onTimePercent: 96, latePercent: 3, absentPercent: 1),
        DailyAttendanceMetric(dayName: 'Thu', onTimePercent: 93, latePercent: 5, absentPercent: 2),
        DailyAttendanceMetric(dayName: 'Fri', onTimePercent: 90, latePercent: 7, absentPercent: 3),
        DailyAttendanceMetric(dayName: 'Sat', onTimePercent: 97, latePercent: 2, absentPercent: 1),
        DailyAttendanceMetric(dayName: 'Sun', onTimePercent: 95, latePercent: 4, absentPercent: 1),
      ],
      branchMetrics: const [
        BranchPerformanceMetric(
          branchId: 'branch-dt-01',
          branchName: 'Downtown Flagship',
          attendanceRate: 97.2,
          activeEmployees: 14,
          pendingExceptions: 3,
          returnCount: 16,
        ),
        BranchPerformanceMetric(
          branchId: 'branch-ns-02',
          branchName: 'North Suburb Terminal',
          attendanceRate: 94.6,
          activeEmployees: 12,
          pendingExceptions: 5,
          returnCount: 14,
        ),
        BranchPerformanceMetric(
          branchId: 'branch-wh-03',
          branchName: 'Airport Logistics Hub',
          attendanceRate: 96.0,
          activeEmployees: 18,
          pendingExceptions: 4,
          returnCount: 12,
        ),
      ],
      returnCategories: const [
        CategoryReturnMetric(categoryName: 'Damaged in Transit', count: 18, percentage: 42.8),
        CategoryReturnMetric(categoryName: 'Expired Shelf-Life', count: 14, percentage: 33.3),
        CategoryReturnMetric(categoryName: 'Customer Returns', count: 6, percentage: 14.3),
        CategoryReturnMetric(categoryName: 'Wrong Item Supplied', count: 4, percentage: 9.6),
      ],
    );
  }
}
