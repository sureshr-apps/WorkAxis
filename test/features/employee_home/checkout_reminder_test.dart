import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart'
    as att;
import 'package:workaxis/features/employee_home/domain/models/attendance_session.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/presentation/models/checkout_notice.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/hero_attendance_card.dart';

final DateTime _checkIn = DateTime.utc(2026, 11, 6, 15, 30); // 21:00 IST

/// Night shift 21:00–05:00 IST starting Nov 6; reminder at 05:15 IST and
/// overdue at 07:00 IST.
att.AttendanceEntry _nightShift({
  DateTime? checkOutAt,
  att.CheckoutStatus checkoutStatus = att.CheckoutStatus.none,
  DateTime? sessionClosedAt,
  bool scheduled = true,
}) => att.AttendanceEntry(
  id: 'night',
  organizationId: 'org-acme',
  branchId: 'br-01',
  employeeId: 'user-emp-01',
  employeeName: 'Sarah Connor',
  workDate: DateTime(2026, 11, 6),
  status: att.AttendanceStatus.present,
  reviewStatus: att.AttendanceReviewStatus.none,
  checkInAt: _checkIn,
  checkOutAt: checkOutAt,
  scheduledStartAt: scheduled ? _checkIn : null,
  scheduledEndAt: scheduled ? DateTime.utc(2026, 11, 6, 23, 30) : null,
  checkoutReminderAt: DateTime.utc(2026, 11, 6, 23, 45),
  checkoutOverdueAt: DateTime.utc(2026, 11, 7, 1, 30),
  checkoutStatus: checkoutStatus,
  sessionClosedAt: sessionClosedAt,
);

/// IST wall-clock time on Nov 6/7 as a UTC instant.
DateTime _ist(int day, int hour, [int minute = 0]) => DateTime.utc(
  2026,
  11,
  day,
  hour,
  minute,
).subtract(const Duration(hours: 5, minutes: 30));

EmployeeHomeSummary _summary(att.AttendanceEntry entry) => EmployeeHomeSummary(
  employeeId: 'user-emp-01',
  employeeName: 'Sarah Connor',
  branchName: 'Downtown Flagship',
  shiftName: 'Night Shift',
  shiftHours: EmployeeHomeSummary.unavailable,
  currentStatus: AttendanceStatus.checkedIn,
  workingDuration: '8h 30m',
  shiftProgress: 1,
  locationStatus: 'Location verified at check-in',
  isWithinGeofence: true,
  session: AttendanceSession(checkIn: _checkIn, standardSeconds: 8 * 3600),
  attendanceEntry: entry,
);

Future<void> _pumpHero(WidgetTester tester, CheckoutNotice? notice) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HeroAttendanceCard(
              summary: _summary(_nightShift()),
              isProcessing: false,
              onPrimaryAction: () {},
              onCheckOut: () {},
              checkoutNotice: notice,
            ),
          ),
        ),
      ),
    );

void main() {
  group('CheckoutNotice', () {
    test('nothing while the shift is running', () {
      expect(CheckoutNotice.of(_nightShift(), _ist(7, 2)), isNull);
      expect(CheckoutNotice.of(_nightShift(), _ist(7, 5, 10)), isNull);
    });

    test('reminds after the shift end with its time in IST', () {
      final notice = CheckoutNotice.of(_nightShift(), _ist(7, 5, 20))!;
      expect(notice.isOverdue, isFalse);
      expect(
        notice.message,
        'Your shift ended at 5:00 AM. Check out when you leave.',
      );
    });

    test('warns once the overtime allowance passes', () {
      final notice = CheckoutNotice.of(_nightShift(), _ist(7, 7, 30))!;
      expect(notice.isOverdue, isTrue);
      expect(notice.title, 'Check-out overdue');
      expect(notice.message, contains('Your shift ended at 5:00 AM'));
      expect(notice.message, contains('manager'));
    });

    test('a server overdue flag wins before the stored deadline', () {
      final notice = CheckoutNotice.of(
        _nightShift(checkoutStatus: att.CheckoutStatus.overdue),
        _ist(7, 2),
      );
      expect(notice?.isOverdue, isTrue);
    });

    test('an unscheduled session still gets a plain message', () {
      final notice = CheckoutNotice.of(
        _nightShift(scheduled: false),
        _ist(7, 5, 20),
      )!;
      expect(notice.message, 'Your shift has ended. Check out when you leave.');
    });

    test('nothing for a checked-out or system-closed session', () {
      final late = _ist(7, 8);
      expect(
        CheckoutNotice.of(_nightShift(checkOutAt: _ist(7, 5)), late),
        isNull,
      );
      expect(
        CheckoutNotice.of(
          _nightShift(
            checkoutStatus: att.CheckoutStatus.missing,
            sessionClosedAt: _ist(7, 13),
          ),
          _ist(7, 14),
        ),
        isNull,
      );
      expect(CheckoutNotice.of(null, late), isNull);
    });
  });

  group('HeroAttendanceCard check-out reminder', () {
    testWidgets('shows the night shift window in IST', (tester) async {
      await _pumpHero(tester, null);
      expect(find.text('Shift 9:00 PM – 5:00 AM'), findsOneWidget);
      expect(find.text('Shift ended'), findsNothing);
      expect(find.text('Check-out overdue'), findsNothing);
    });

    testWidgets('reminder keeps check-out available', (tester) async {
      await _pumpHero(tester, CheckoutNotice.of(_nightShift(), _ist(7, 5, 20)));
      expect(find.text('Shift ended'), findsOneWidget);
      expect(
        find.text('Your shift ended at 5:00 AM. Check out when you leave.'),
        findsOneWidget,
      );
      expect(find.text('Check Out'), findsOneWidget);
    });

    testWidgets('overdue shows the stronger warning', (tester) async {
      await _pumpHero(tester, CheckoutNotice.of(_nightShift(), _ist(7, 8)));
      expect(find.text('Check-out overdue'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('will review this session'), findsOneWidget);
      expect(find.text('Check Out'), findsOneWidget);
    });
  });
}
