import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/employee_home/domain/models/attendance_session.dart';

void main() {
  final checkIn = DateTime.utc(2026, 11, 18, 3, 0);

  group('AttendanceSession', () {
    test('a running session counts time up to the moment it is read', () {
      final session = AttendanceSession(
        checkIn: checkIn,
        standardSeconds: 8 * 3600,
      );

      expect(session.isRunning, isTrue);
      expect(session.workedAt(DateTime.utc(2026, 11, 18, 3, 42)).inMinutes, 42);
      expect(
        session.workedAt(DateTime.utc(2026, 11, 18, 4, 42)).inMinutes,
        102,
      );
    });

    test('time on break is not counted, including a break still open', () {
      final session = AttendanceSession(
        checkIn: checkIn,
        standardSeconds: 8 * 3600,
        breaks: [
          AttendanceBreak(
            start: DateTime.utc(2026, 11, 18, 4, 0),
            end: DateTime.utc(2026, 11, 18, 4, 30),
          ),
          AttendanceBreak(start: DateTime.utc(2026, 11, 18, 5, 0)),
        ],
      );

      // 03:00 -> 05:00 is 120 minutes, less the 30 minute closed break and
      // the open break, which runs from 05:00 until the moment of reading.
      expect(session.workedAt(DateTime.utc(2026, 11, 18, 5, 20)).inMinutes, 90);
    });

    test('a checked-out session stops counting at check-out', () {
      final session = AttendanceSession(
        checkIn: checkIn,
        checkOut: DateTime.utc(2026, 11, 18, 7, 0),
        standardSeconds: 8 * 3600,
      );

      expect(session.isRunning, isFalse);
      expect(session.workedAt(DateTime.utc(2026, 11, 18, 9, 0)).inMinutes, 240);
    });

    test('progress is the share of the standard day, capped at 100%', () {
      final session = AttendanceSession(
        checkIn: checkIn,
        standardSeconds: 4 * 3600,
      );

      expect(
        session.progressAt(DateTime.utc(2026, 11, 18, 5, 0)),
        closeTo(0.5, 1e-9),
      );
      expect(session.progressAt(DateTime.utc(2026, 11, 18, 12, 0)), 1.0);
    });

    test('durations are shown as hours and two-digit minutes', () {
      expect(
        AttendanceSession.formatDuration(const Duration(hours: 5, minutes: 7)),
        '5h 07m',
      );
    });
  });
}
