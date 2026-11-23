import 'dart:math' as math;

import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';

/// Plausible paid/unpaid split for the mock backend. It does not replicate the
/// server ledger (accrual, carry-forward, schedules): working days are every
/// day except Sunday, and the balance is the yearly allowance minus the
/// working days of approved leave of the same type in the start date's year.
class MockLeavePreviewCalculator {
  const MockLeavePreviewCalculator();

  LeavePreview preview({
    required LeaveTypeOption type,
    required int yearlyDays,
    required DateTime startDate,
    required DateTime endDate,
    required Iterable<LeaveRequest> applicantRequests,
    String? excludeRequestId,
  }) {
    final workdays = workdaysBetween(startDate, endDate);
    if (!type.paid) {
      return LeavePreview(
        leaveTypeId: type.id,
        availableDays: 0,
        workdays: workdays,
        paidDays: 0,
        unpaidDays: workdays,
      );
    }
    final year = startDate.year;
    final used = applicantRequests
        .where(
          (request) =>
              request.id != excludeRequestId &&
              request.status == LeaveStatus.approved &&
              request.leaveTypeId == type.id,
        )
        .fold<int>(
          0,
          (sum, request) =>
              sum +
              workdaysBetween(
                _latest(request.startDate, DateTime(year)),
                _earliest(request.endDate, DateTime(year, 12, 31)),
              ),
        );
    final available = math.max(0, yearlyDays - used);
    final paid = math.min(workdays, available);
    return LeavePreview(
      leaveTypeId: type.id,
      availableDays: available,
      workdays: workdays,
      paidDays: paid,
      unpaidDays: workdays - paid,
    );
  }

  /// Days from [start] to [end] inclusive, excluding Sundays; 0 when [end]
  /// is before [start].
  static int workdaysBetween(DateTime start, DateTime end) {
    var day = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    var count = 0;
    while (!day.isAfter(last)) {
      if (day.weekday != DateTime.sunday) count++;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return count;
  }

  static DateTime _latest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  static DateTime _earliest(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}
