import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/attendance_session_presentation.dart';
import 'package:workaxis/features/attendance/presentation/attendance_time_format.dart';

import 'night_shift_fixtures.dart';

void main() {
  group('AttendanceTimeFormat', () {
    test('formats on the business clock and notes the next day', () {
      expect(AttendanceTimeFormat.time(ist(6, 21)), '9:00 PM');
      expect(
        AttendanceTimeFormat.timeOnShift(ist(7, 5, 10), DateTime(2026, 11, 6)),
        '5:10 AM (next day)',
      );
      expect(
        AttendanceTimeFormat.timeOnShift(ist(6, 23), DateTime(2026, 11, 6)),
        '11:00 PM',
      );
    });

    test('formats hours with at most two decimals', () {
      expect(AttendanceTimeFormat.hours(2), '2h');
      expect(AttendanceTimeFormat.hours(1.5), '1.5h');
      expect(AttendanceTimeFormat.hours(1.25), '1.25h');
      expect(AttendanceTimeFormat.hours(0.333), '0.33h');
    });
  });

  group('AttendanceSessionPresentation', () {
    test('shows a night shift window ending the next day', () {
      expect(
        nightShift().shiftWindowLabel,
        'Shift 9:00 PM – 5:00 AM (next day)',
      );
    });

    test('a missing check-out names the system closure, not a time', () {
      final entry = nightShift(
        checkoutStatus: CheckoutStatus.missing,
        sessionClosedAt: ist(7, 13),
      );
      final display = entry.checkoutStateDisplay!;
      expect(display.label, 'Missing check-out');
      expect(display.type, StatusType.urgent);
      expect(
        display.detail,
        contains('Closed by system at Nov 7, 2026 1:00 PM'),
      );
      expect(display.detail, contains('No check-out was recorded'));
      expect(entry.checkOutLabel, 'Missing');
    });

    test('an unknown closure time still reads as closed by system', () {
      final entry = nightShift(
        checkoutStatus: CheckoutStatus.missing,
        sessionClosedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(
        entry.checkoutStateDisplay!.detail,
        startsWith('Closed by system.'),
      );
    });

    test('overdue, late and corrected states have text labels', () {
      final overdue = nightShift(checkoutStatus: CheckoutStatus.overdue);
      expect(overdue.checkoutStateDisplay!.label, 'Overdue');
      expect(overdue.checkOutLabel, 'Overdue');

      final late = nightShift(
        checkOutAt: ist(7, 11),
        checkoutStatus: CheckoutStatus.late,
      );
      expect(late.checkoutStateDisplay!.label, 'Late check-out');
      expect(late.checkOutLabel, '11:00 AM (next day)');

      final corrected = nightShift(
        checkOutAt: ist(7, 5),
        checkOutCorrected: true,
      );
      expect(corrected.checkoutStateDisplay!.label, 'Corrected');
      expect(corrected.effectiveCheckoutStatus, CheckoutStatus.corrected);
    });

    test('an open session without flags is in progress', () {
      final entry = nightShift();
      expect(entry.checkoutStateDisplay, isNull);
      expect(entry.checkOutLabel, 'In progress');
    });

    test('overtime labels cover pending, approved and rejected', () {
      expect(
        nightShift(
          potentialOvertimeHours: 2,
          overtimeStatus: OvertimeStatus.pending,
        ).overtimeLabel,
        '2h potential OT · Pending',
      );
      expect(
        nightShift(
          potentialOvertimeHours: 2,
          overtimeStatus: OvertimeStatus.approved,
          approvedOvertimeHours: 1.5,
        ).overtimeLabel,
        '1.5h OT approved of 2h',
      );
      expect(
        nightShift(
          potentialOvertimeHours: 2,
          overtimeStatus: OvertimeStatus.approved,
          approvedOvertimeHours: 2,
        ).overtimeLabel,
        '2h OT approved',
      );
      expect(
        nightShift(
          potentialOvertimeHours: 2,
          overtimeStatus: OvertimeStatus.rejected,
        ).overtimeLabel,
        '2h potential OT · Rejected',
      );
      expect(nightShift().overtimeLabel, isNull);
    });

    test('a pending correction is mentioned', () {
      expect(
        nightShift(correctionStatus: CorrectionStatus.pending).correctionLabel,
        'Correction pending review',
      );
    });

    test('worked time excludes completed breaks', () {
      final entry = nightShift(
        checkOutAt: ist(7, 7),
        breaks: [AttendanceBreakRecord(startAt: ist(7, 1), endAt: ist(7, 2))],
      );
      expect(entry.workedDuration, const Duration(hours: 9));
    });
  });

  group('AttendanceDaySummarySessionPresentation', () {
    test('reports the most pressing state and pending overtime', () {
      final summary = AttendanceDaySummary.fromEntries([
        nightShift(
          id: 'a',
          checkOutAt: ist(6, 23),
          checkoutStatus: CheckoutStatus.late,
          potentialOvertimeHours: 1,
          overtimeStatus: OvertimeStatus.pending,
        ),
        nightShift(
          id: 'b',
          checkoutStatus: CheckoutStatus.missing,
          sessionClosedAt: ist(7, 13),
          potentialOvertimeHours: 0.5,
          overtimeStatus: OvertimeStatus.pending,
        ),
      ]).single;

      expect(summary.checkoutStateDisplay!.label, 'Missing check-out');
      expect(summary.lastCheckOutLabel, 'Missing');
      expect(summary.overtimeLabel, '1.5h potential OT · Pending');
      expect(summary.overtimeChipType, StatusType.pending);
      expect(summary.shiftWindowLabel, 'Shift 9:00 PM – 5:00 AM (next day)');
    });

    test('a finished night shift shows its next-day check-out', () {
      final summary = AttendanceDaySummary.fromEntries([
        nightShift(checkOutAt: ist(7, 5, 5)),
      ]).single;
      expect(summary.lastCheckOutLabel, '5:05 AM (next day)');
      expect(summary.checkoutStateDisplay, isNull);
    });
  });
}
