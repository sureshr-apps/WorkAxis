import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_exceptions_repository.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_exceptions_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employee_home/data/mock_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/validators/checkout_correction_validator.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/checkout_corrections_controller.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';
import 'package:workaxis/features/employee_home/presentation/formatting/business_time_text.dart';
import 'package:workaxis/features/employee_home/presentation/screens/employee_home_screen.dart';

import '../../helpers/access_controller_fixture.dart';
import '../../helpers/access_fixtures.dart';
import '../../helpers/fallback_maps.dart';
import '../../helpers/fixed_clock.dart';

/// Night shift 21:00–05:00 IST on Nov 6, closed by the system without a
/// check-out. [testNow] is 10:30 IST on Nov 7.
AttendanceEntry _missing({
  String id = 'night-missing',
  String employeeId = 'user-emp-01',
  DateTime? checkOutAt,
  CheckoutStatus checkoutStatus = CheckoutStatus.missing,
  List<AttendanceBreakRecord> breaks = const [],
}) => AttendanceEntry(
  id: id,
  organizationId: 'org-acme',
  branchId: 'br-01',
  employeeId: employeeId,
  employeeName: 'Sarah Connor',
  workDate: DateTime(2026, 11, 6),
  status: AttendanceStatus.incomplete,
  reviewStatus: AttendanceReviewStatus.needsReview,
  checkInAt: DateTime.utc(2026, 11, 6, 15, 30),
  checkOutAt: checkOutAt,
  breaks: breaks,
  scheduledStartAt: DateTime.utc(2026, 11, 6, 15, 30),
  scheduledEndAt: DateTime.utc(2026, 11, 6, 23, 30),
  checkoutStatus: checkoutStatus,
  sessionClosedAt: checkOutAt == null ? DateTime.utc(2026, 11, 7, 7) : null,
);

class _FailingExceptions extends MockAttendanceExceptionsRepository {
  _FailingExceptions() : super(now: fixedNow, entries: [_missing()]);

  bool failLoads = false;

  @override
  Future<List<AttendanceEntry>> getCorrectableEntries({
    required UserAccessContext access,
  }) async {
    if (failLoads) throw const NetworkException();
    return super.getCorrectableEntries(access: access);
  }

  @override
  Future<void> requestCheckoutCorrection({
    required UserAccessContext access,
    required String entryId,
    required DateTime checkOutAt,
    required String reason,
  }) async => throw const DatabaseException(
    'failed-precondition',
    userMessage: 'A correction is already waiting for review.',
  );
}

final Finder _reasonField = find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(EditableText),
);

String? _checkOutError(AttendanceEntry entry, DateTime? at) =>
    CheckoutCorrectionValidator.checkOutError(
      entry: entry,
      checkOutAt: at,
      now: testNow,
      formatTime: BusinessTimeText.shortDateTime,
    );

void main() {
  group('CheckoutCorrectionValidator', () {
    final scheduledEnd = DateTime.utc(2026, 11, 6, 23, 30);

    test('accepts the scheduled shift end of a missing check-out', () {
      expect(_checkOutError(_missing(), scheduledEnd), isNull);
    });

    test('rejects a missing, early, future or too-late time', () {
      final entry = _missing();
      expect(_checkOutError(entry, null), contains('Choose'));
      expect(
        _checkOutError(entry, DateTime.utc(2026, 11, 6, 15)),
        contains('after your check-in at Nov 6, 9:00 PM'),
      );
      expect(
        _checkOutError(entry, testNow.add(const Duration(minutes: 1))),
        contains('future'),
      );
    });

    test('must follow the last break and stay within 24 hours', () {
      final withBreak = _missing(
        breaks: [
          AttendanceBreakRecord(
            startAt: DateTime.utc(2026, 11, 6, 20),
            endAt: DateTime.utc(2026, 11, 6, 20, 30),
          ),
        ],
      );
      expect(
        _checkOutError(withBreak, DateTime.utc(2026, 11, 6, 20, 15)),
        contains('last break'),
      );
      final longAgo = AttendanceEntry(
        id: 'old',
        organizationId: 'org-acme',
        branchId: 'br-01',
        employeeId: 'user-emp-01',
        employeeName: 'Sarah Connor',
        workDate: DateTime(2026, 11, 5),
        status: AttendanceStatus.incomplete,
        reviewStatus: AttendanceReviewStatus.none,
        checkInAt: DateTime.utc(2026, 11, 5, 3),
        checkoutStatus: CheckoutStatus.missing,
      );
      expect(
        _checkOutError(longAgo, DateTime.utc(2026, 11, 6, 4)),
        contains('within 24 hours'),
      );
    });

    test('a late check-out can only move earlier', () {
      final late = _missing(
        checkoutStatus: CheckoutStatus.late,
        checkOutAt: DateTime.utc(2026, 11, 7, 4, 10), // 09:40 IST
      );
      expect(
        _checkOutError(late, DateTime.utc(2026, 11, 7, 4, 10)),
        contains('earlier than the recorded check-out at Nov 7, 9:40 AM'),
      );
      expect(_checkOutError(late, scheduledEnd), isNull);
    });

    test('reason is required and at most 500 characters', () {
      expect(CheckoutCorrectionValidator.reasonError('   '), isNotNull);
      expect(CheckoutCorrectionValidator.reasonError('x' * 501), isNotNull);
      expect(CheckoutCorrectionValidator.reasonError('Forgot'), isNull);
    });
  });

  group('CheckoutCorrectionsController', () {
    test('loads, submits and refreshes the list', () async {
      final controller = CheckoutCorrectionsController(
        repository: MockAttendanceExceptionsRepository(
          now: fixedNow,
          entries: [
            _missing(),
            _missing(id: 'colleague', employeeId: 'x'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      await controller.load(access: employeeAccess());
      expect(controller.entries.map((e) => e.id), ['night-missing']);

      final sent = await controller.requestCorrection(
        entryId: 'night-missing',
        checkOutAt: DateTime.utc(2026, 11, 6, 23, 30),
        reason: '  Forgot to check out  ',
      );

      expect(sent, isTrue);
      expect(controller.entries, isEmpty);
      expect(controller.submitErrorMessage, isNull);
    });

    test('load failures show a user message', () async {
      final repository = _FailingExceptions()..failLoads = true;
      final controller = CheckoutCorrectionsController(repository: repository);
      addTearDown(controller.dispose);

      await controller.load(access: employeeAccess());

      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, isNotNull);
    });
  });

  group('Employee Home correction flow', () {
    Future<void> pumpHome(
      WidgetTester tester,
      AttendanceExceptionsRepository exceptions,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final home = EmployeeHomeController(
        repository: MockEmployeeHomeRepository(delay: Duration.zero),
      );
      final access = await resolvedAccessController(
        UserRole.employee,
        'user-emp-01',
        name: 'Sarah Connor',
      );
      final branches = BranchContextController()
        ..initFromAccessContext(access.accessContext!);
      await tester.pumpWidget(
        MaterialApp(
          builder: fallbackMapsBuilder,
          theme: AppTheme.light,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AccessController>.value(value: access),
              ChangeNotifierProvider<BranchContextController>.value(
                value: branches,
              ),
              ChangeNotifierProvider<EmployeeHomeController>.value(value: home),
              Provider<AttendanceExceptionsRepository>.value(value: exceptions),
            ],
            child: const EmployeeHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openDialog(WidgetTester tester) async {
      final action = find.text('Request correction');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
    }

    testWidgets('hidden when nothing needs correcting', (tester) async {
      await pumpHome(
        tester,
        MockAttendanceExceptionsRepository(now: fixedNow, entries: const []),
      );
      expect(find.text('Check-outs to correct'), findsNothing);
    });

    testWidgets('validates, submits and refreshes the list', (tester) async {
      final exceptions = MockAttendanceExceptionsRepository(
        now: fixedNow,
        entries: [_missing()],
      );
      await pumpHome(tester, exceptions);

      expect(find.text('Check-outs to correct'), findsOneWidget);
      expect(find.text('Shift Nov 6'), findsOneWidget);
      expect(find.text('Checked in 9:00 PM'), findsOneWidget);
      expect(find.text('Missing check-out'), findsOneWidget);

      await openDialog(tester);
      expect(find.text('Request check-out correction'), findsOneWidget);
      // Defaults to the scheduled shift end.
      expect(find.text('Actual check-out: Nov 7, 5:00 AM IST'), findsOneWidget);

      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(
        find.text('Explain why the check-out needs correcting.'),
        findsOneWidget,
      );

      await tester.enterText(_reasonField, 'Forgot to check out when leaving');
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();

      expect(find.text('Request check-out correction'), findsNothing);
      expect(find.textContaining('Correction request sent'), findsOneWidget);
      expect(find.text('Check-outs to correct'), findsNothing);
      final remaining = await exceptions.getCorrectableEntries(
        access: employeeAccess(),
      );
      expect(remaining, isEmpty);
    });

    testWidgets('a server rejection stays in the dialog', (tester) async {
      await pumpHome(tester, _FailingExceptions());

      await openDialog(tester);
      await tester.enterText(_reasonField, 'Forgot to check out');
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();

      expect(find.text('Request check-out correction'), findsOneWidget);
      expect(
        find.text('A correction is already waiting for review.'),
        findsOneWidget,
      );
    });

    testWidgets('a failed load shows a retry', (tester) async {
      await pumpHome(tester, _FailingExceptions()..failLoads = true);

      expect(find.text('Check-outs to correct'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
