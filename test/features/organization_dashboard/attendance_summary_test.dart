import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';

AttendanceSummary _summary({
  required int present,
  int late = 0,
  int absent = 0,
  int? onLeave,
  required int totalScheduled,
}) => AttendanceSummary(
  present: present,
  late: late,
  absent: absent,
  onLeave: onLeave,
  totalScheduled: totalScheduled,
);

void main() {
  group('AttendanceSummary.level', () {
    test('an 80% rate or better reads as high', () {
      final summary = _summary(present: 80, absent: 20, totalScheduled: 100);
      expect(summary.level, AttendanceLevel.high);
    });

    test('just under 80% reads as medium', () {
      final summary = _summary(present: 79, absent: 21, totalScheduled: 100);
      expect(summary.level, AttendanceLevel.medium);
    });

    test('60% reads as medium and just under reads as low', () {
      expect(
        _summary(present: 60, absent: 40, totalScheduled: 100).level,
        AttendanceLevel.medium,
      );
      expect(
        _summary(present: 59, absent: 41, totalScheduled: 100).level,
        AttendanceLevel.low,
      );
    });

    test('no scheduled roster reads as low, since the rate is zero', () {
      final summary = _summary(present: 0, totalScheduled: 0);
      expect(summary.attendanceRate, 0.0);
      expect(summary.level, AttendanceLevel.low);
    });
  });

  group('AttendanceSummary.barTotal', () {
    test('adds approved leave on top of the scheduled roster', () {
      final summary = _summary(
        present: 389,
        late: 15,
        absent: 24,
        onLeave: 15,
        totalScheduled: 428,
      );
      expect(summary.distributionTotal, 428);
      expect(summary.barTotal, 443);
    });

    test('equals the scheduled roster when leave is not tracked', () {
      final summary = _summary(
        present: 389,
        late: 15,
        absent: 24,
        totalScheduled: 428,
      );
      expect(summary.barTotal, 428);
    });

    test('does not count leave twice when there is no roster', () {
      final summary = _summary(
        present: 5,
        late: 1,
        absent: 2,
        onLeave: 3,
        totalScheduled: 0,
      );
      expect(summary.distributionTotal, 11);
      expect(summary.barTotal, 11);
    });
  });
}
