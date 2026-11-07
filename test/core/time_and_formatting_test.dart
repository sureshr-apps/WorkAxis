import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';

import '../helpers/fixed_clock.dart';

void main() {
  group('Clock', () {
    test('fixed clock always returns the same instant', () {
      final clock = Clock.fixed(DateTime(2026, 1, 2, 3, 4));
      expect(clock.now(), DateTime(2026, 1, 2, 3, 4));
      expect(clock.now(), clock.now());
    });

    test('default clock follows the system time', () {
      final before = DateTime.now();
      final now = Clock().now();
      expect(now.isBefore(before), isFalse);
    });

    test('controllers take their date from the injected clock', () {
      final controller = AttendanceController(
        repository: MockAttendanceRepository(now: fixedNow),
        now: fixedNow,
      );
      addTearDown(controller.dispose);

      expect(controller.selectedDate, DateTime(2026, 11, 7));
      controller.reset();
      expect(controller.selectedDate, DateTime(2026, 11, 7));
    });
  });

  group('AppFormatters', () {
    test('formatTime is the canonical h:mm a format', () {
      expect(AppFormatters.formatTime(DateTime(2026, 11, 7, 9, 5)), '9:05 AM');
      expect(
        AppFormatters.formatTime(DateTime(2026, 11, 7, 21, 30)),
        '9:30 PM',
      );
      expect(AppFormatters.formatTime(null), '--');
      expect(AppFormatters.formatTime(null, placeholder: 'n/a'), 'n/a');
    });

    test('dates and date-times', () {
      final value = DateTime(2026, 11, 7, 14, 5);
      expect(AppFormatters.formatDate(value), 'Nov 7, 2026');
      expect(AppFormatters.formatShortDate(value), 'Nov 7');
      expect(AppFormatters.formatDateTime(value), 'Nov 7, 2026 2:05 PM');
    });

    test('currency uses the rupee symbol and Indian grouping', () {
      expect(AppFormatters.formatCurrencyInr(125000), '₹1,25,000');
      expect(AppFormatters.formatNumber(12345), '12,345');
    });
  });
}
