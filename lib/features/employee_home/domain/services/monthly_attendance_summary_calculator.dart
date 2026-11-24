import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/employees/domain/models/employee_workforce_history.dart';

typedef MonthlyAttendanceMetrics = ({
  int? present,
  int? late,
  int? absent,
  int? adherencePercentage,
});

/// Derives one employee's attendance metrics from effective schedules and
/// branch-specific attendance sessions for the current calendar month.
abstract final class MonthlyAttendanceSummaryCalculator {
  static const unavailable = (
    present: null,
    late: null,
    absent: null,
    adherencePercentage: null,
  );

  static MonthlyAttendanceMetrics calculate({
    required DateTime today,
    required Iterable<ScheduleVersion> schedules,
    required Iterable<AttendanceEntry> entries,
  }) {
    final scheduleHistory = schedules.toList(growable: false);
    if (scheduleHistory.isEmpty) return unavailable;

    final summariesByDate = {
      for (final summary in AttendanceDaySummary.fromEntries(entries))
        BusinessTime.keyOfDate(summary.workDate): summary,
    };

    var hasScheduleCoverage = false;
    var scheduledDays = 0;
    var presentDays = 0;
    var lateDays = 0;
    var absentDays = 0;

    for (var day = 1; day <= today.day; day++) {
      final date = DateTime(today.year, today.month, day);
      final schedule = _scheduleForDate(scheduleHistory, date);
      if (schedule == null) continue;
      hasScheduleCoverage = true;

      // ScheduleVersion stores Sunday as 0 through Saturday as 6.
      if (schedule.weeklyDaysOff.contains(date.weekday % 7)) continue;

      scheduledDays++;
      final dailyAttendance = summariesByDate[BusinessTime.keyOfDate(date)];
      switch (dailyAttendance?.status) {
        case AttendanceStatus.present:
          presentDays++;
          break;
        case AttendanceStatus.late:
          lateDays++;
          break;
        case AttendanceStatus.absent:
        case AttendanceStatus.incomplete:
        case null:
          // A scheduled day without a completed present or late record counts
          // as absent in the employee summary.
          absentDays++;
          break;
      }
    }

    if (!hasScheduleCoverage) return unavailable;

    return (
      present: presentDays,
      late: lateDays,
      absent: absentDays,
      adherencePercentage: scheduledDays == 0
          ? null
          : (presentDays * 100 / scheduledDays).round(),
    );
  }

  static ScheduleVersion? _scheduleForDate(
    List<ScheduleVersion> schedules,
    DateTime date,
  ) {
    final dateKey = BusinessTime.keyOfDate(date);
    return schedules.where((schedule) {
      final effectiveFrom = BusinessTime.keyOfDate(schedule.effectiveFrom);
      final effectiveTo = schedule.effectiveTo == null
          ? null
          : BusinessTime.keyOfDate(schedule.effectiveTo!);
      return effectiveFrom.compareTo(dateKey) <= 0 &&
          (effectiveTo == null || dateKey.compareTo(effectiveTo) < 0);
    }).firstOrNull;
  }
}
