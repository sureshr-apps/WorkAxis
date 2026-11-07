import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/reports/domain/models/report_period.dart';

/// Half-open instant range `[from, to)` a [ReportPeriod] covers.
class ReportRange {
  const ReportRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

/// Resolves a [ReportPeriod] to instants using the business calendar
/// (Asia/Kolkata), never the device-local date. Open periods end at the start
/// of the next business day so that today's records are included.
abstract final class ReportPeriodRange {
  static ReportRange resolve(ReportPeriod period, Now now) {
    final today = BusinessTime.today(now);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final DateTime start;
    DateTime end = tomorrow;
    switch (period) {
      case ReportPeriod.thisWeek:
        start = DateTime(
          today.year,
          today.month,
          today.day - (today.weekday - DateTime.monday),
        );
      case ReportPeriod.thisMonth:
        start = DateTime(today.year, today.month);
      case ReportPeriod.lastMonth:
        start = DateTime(today.year, today.month - 1);
        end = DateTime(today.year, today.month);
      case ReportPeriod.quarterToDate:
        start = DateTime(today.year, ((today.month - 1) ~/ 3) * 3 + 1);
    }
    return ReportRange(
      from: BusinessTime.startOfDay(start),
      to: BusinessTime.startOfDay(end),
    );
  }
}
