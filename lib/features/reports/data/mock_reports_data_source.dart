import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/domain/models/report_period.dart';

/// Canned report figures for the mock backend. Branch identity always comes
/// from the branches the caller is scoped to.
class MockReportsDataSource {
  OperationalReportSummary getSummary({
    required List<BranchSummary> branches,
    required ReportPeriod period,
  }) {
    final metrics = [
      for (var i = 0; i < branches.length; i++)
        BranchPerformanceMetric(
          branchId: branches[i].id,
          branchName: branches[i].name,
          attendanceRate: _rates[i % _rates.length],
          activeEmployees: branches[i].activeEmployeeCount,
          pendingExceptions: (i * 2 + 1) % 5,
          returnCount: 4 + i * 3,
        ),
    ];
    final totalReturns = metrics.fold<int>(0, (sum, m) => sum + m.returnCount);
    final single = branches.length == 1;

    return OperationalReportSummary(
      period: period,
      attendanceRate: single ? 97.2 : 95.8,
      onTimeRate: single ? 94.5 : 91.4,
      totalHoursLogged: single ? 428.0 : 1684.0,
      exceptionCount: metrics.fold<int>(0, (s, m) => s + m.pendingExceptions!),
      returnVolume: totalReturns,
      returnRate: 1.2,
      dailyTrends: const [
        DailyAttendanceMetric(
          dayName: 'Mon',
          onTimePercent: 94,
          latePercent: 4,
          absentPercent: 2,
        ),
        DailyAttendanceMetric(
          dayName: 'Tue',
          onTimePercent: 91,
          latePercent: 6,
          absentPercent: 3,
        ),
        DailyAttendanceMetric(
          dayName: 'Wed',
          onTimePercent: 96,
          latePercent: 3,
          absentPercent: 1,
        ),
        DailyAttendanceMetric(
          dayName: 'Thu',
          onTimePercent: 93,
          latePercent: 5,
          absentPercent: 2,
        ),
        DailyAttendanceMetric(
          dayName: 'Fri',
          onTimePercent: 90,
          latePercent: 7,
          absentPercent: 3,
        ),
        DailyAttendanceMetric(
          dayName: 'Sat',
          onTimePercent: 97,
          latePercent: 2,
          absentPercent: 1,
        ),
        DailyAttendanceMetric(
          dayName: 'Sun',
          onTimePercent: 95,
          latePercent: 4,
          absentPercent: 1,
        ),
      ],
      branchMetrics: metrics,
      returnCategories: const [
        CategoryReturnMetric(
          categoryName: 'Damaged Products',
          count: 5,
          percentage: 45.5,
        ),
        CategoryReturnMetric(
          categoryName: 'Expired Stock',
          count: 4,
          percentage: 36.4,
        ),
        CategoryReturnMetric(
          categoryName: 'Wrong Item Supplied',
          count: 1,
          percentage: 9.1,
        ),
        CategoryReturnMetric(
          categoryName: 'Customer Returned',
          count: 1,
          percentage: 9.0,
        ),
      ],
    );
  }

  static const _rates = [97.2, 94.6, 96.0, 92.5];
}
