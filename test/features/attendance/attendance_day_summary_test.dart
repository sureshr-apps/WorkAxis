import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

void main() {
  final day = DateTime(2026, 11, 20);
  final firstIn = DateTime(2026, 11, 20, 9);
  final firstOut = DateTime(2026, 11, 20, 12);
  final secondIn = DateTime(2026, 11, 20, 13);
  final secondOut = DateTime(2026, 11, 20, 17);

  AttendanceEntry session({
    required String id,
    String employeeId = 'employee-1',
    DateTime? workDate,
    required String branchId,
    required DateTime? checkInAt,
    DateTime? checkOutAt,
    AttendanceStatus status = AttendanceStatus.present,
    AttendanceReviewStatus reviewStatus = AttendanceReviewStatus.none,
  }) => AttendanceEntry(
    id: id,
    organizationId: 'org-1',
    branchId: branchId,
    employeeId: employeeId,
    employeeName: 'Casey Employee',
    workDate: workDate ?? day,
    checkInAt: checkInAt,
    checkOutAt: checkOutAt,
    status: status,
    reviewStatus: reviewStatus,
  );

  test('groups sequential branch sessions into one employee/day summary', () {
    final summaries = AttendanceDaySummary.fromEntries([
      session(
        id: 'session-2',
        branchId: 'branch-b',
        checkInAt: secondIn,
        checkOutAt: secondOut,
        status: AttendanceStatus.late,
        reviewStatus: AttendanceReviewStatus.needsReview,
      ),
      session(
        id: 'session-1',
        branchId: 'branch-a',
        checkInAt: firstIn,
        checkOutAt: firstOut,
      ),
      session(
        id: 'another-employee',
        employeeId: 'employee-2',
        branchId: 'branch-a',
        checkInAt: firstIn,
      ),
      session(
        id: 'another-day',
        workDate: DateTime(2026, 11, 21),
        branchId: 'branch-a',
        checkInAt: firstIn,
      ),
    ]);

    expect(summaries, hasLength(3));
    final summary = summaries.firstWhere(
      (item) => item.employeeId == 'employee-1',
    );
    expect(summary.sessions.map((item) => item.id), ['session-1', 'session-2']);
    expect(summary.branchIds, ['branch-a', 'branch-b']);
    expect(summary.firstCheckIn, firstIn);
    expect(summary.lastCheckOut, secondOut);
    expect(summary.status, AttendanceStatus.late);
    expect(summary.needsReviewCount, 1);
  });

  test('open sessions keep the daily last checkout in progress', () {
    final summary = AttendanceDaySummary.fromEntries([
      session(
        id: 'session-1',
        branchId: 'branch-a',
        checkInAt: firstIn,
        checkOutAt: firstOut,
      ),
      session(id: 'session-2', branchId: 'branch-b', checkInAt: secondIn),
    ]).single;

    expect(summary.lastCheckOut, isNull);
  });
}
