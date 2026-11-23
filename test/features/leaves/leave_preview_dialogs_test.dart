import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leaves/data/mock_leaves_data_source.dart';
import 'package:workaxis/features/leaves/data/mock_leaves_repository.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';
import 'package:workaxis/features/leaves/presentation/controllers/leave_preview_controller.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_preview_summary.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_request_form_dialog.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_review_dialog.dart';

import '../../helpers/access_fixtures.dart';
import 'leave_fixtures.dart';

void main() {
  group('LeavePreviewMessage', () {
    LeavePreview preview({int available = 2, int workdays = 3}) {
      final paid = workdays < available ? workdays : available;
      return LeavePreview(
        leaveTypeId: 'lt-annual',
        availableDays: available,
        workdays: workdays,
        paidDays: paid,
        unpaidDays: workdays - paid,
      );
    }

    test('splits the unpaid part out for the warning colour', () {
      final message = LeavePreviewMessage.describe(
        typeName: 'Annual leave',
        paid: true,
        preview: preview(),
      );

      expect(
        message.lead,
        'Annual leave: 2 days available · 3 working days requested — 2 paid, ',
      );
      expect(message.unpaid, '1 unpaid (deducted from salary)');
    });

    test('a fully paid request has no unpaid part', () {
      final message = LeavePreviewMessage.describe(
        typeName: 'Annual leave',
        paid: true,
        preview: preview(available: 5, workdays: 1),
      );

      expect(
        message.text,
        'Annual leave: 5 days available · 1 working day requested — 1 paid.',
      );
      expect(message.unpaid, isNull);
    });

    test('an unpaid type says it is not paid', () {
      final message = LeavePreviewMessage.describe(
        typeName: 'Unpaid leave',
        paid: false,
        preview: preview(available: 0),
      );

      expect(message.lead, 'Unpaid leave is not paid. ');
      expect(
        message.unpaid,
        '3 working days requested (deducted from salary).',
      );
    });
  });

  group('leave dialogs', () {
    late MockLeavesDataSource dataSource;
    late MockLeavesRepository repository;

    setUp(() {
      // Monday; the seeded approved sick leave covers Wed 18 – Thu 19 Nov.
      dataSource = MockLeavesDataSource(now: () => DateTime(2026, 11, 23, 9));
      repository = MockLeavesRepository(dataSource, delay: Duration.zero);
    });

    LeavePreviewController previewFor(
      UserAccessContext access, {
      String? activeBranchId,
    }) => LeavePreviewController(
      repository: repository,
      access: access,
      activeBranchId: activeBranchId,
      debounce: Duration.zero,
    );

    Future<void> pumpDialog(WidgetTester tester, Widget dialog) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: dialog)));
      await tester.pumpAndSettle();
    }

    for (final size in [const Size(375, 812), const Size(1280, 900)]) {
      testWidgets('form shows the paid/unpaid split at ${size.width}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final access = employeeAccess();
        final preview = previewFor(access);
        addTearDown(preview.dispose);

        await pumpDialog(
          tester,
          LeaveRequestFormDialog(
            branches: access.activeAssignedBranches,
            initialBranchId: 'br-01',
            branchLocked: false,
            loadLeaveTypes: () => repository.getLeaveTypes(access: access),
            preview: preview,
            onSubmit: (_) async => true,
            failureMessage: null,
            // Mon 30 Nov – Sun 6 Dec: 6 working days, 4 sick days left.
            request: leaveRequest(
              type: sickLeave,
              startDate: DateTime(2026, 11, 30),
              endDate: DateTime(2026, 12, 6),
            ),
          ),
        );

        expect(
          find.textContaining(
            'Sick leave: 4 days available · 6 working days requested — 4 paid',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('2 unpaid (deducted from salary)'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Sick leave').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Unpaid leave').last);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Unpaid leave is not paid.'),
          findsOneWidget,
        );
        expect(find.textContaining('4 days available'), findsNothing);
      });
    }

    testWidgets('form keeps submitting possible when the preview fails', (
      tester,
    ) async {
      final access = employeeAccess();
      final preview = previewFor(access);
      addTearDown(preview.dispose);
      LeaveRequestFormResult? submitted;

      await pumpDialog(
        tester,
        LeaveRequestFormDialog(
          branches: access.activeAssignedBranches,
          initialBranchId: 'br-01',
          branchLocked: false,
          loadLeaveTypes: () async => [
            annualLeave,
            // Not known to the mock backend, so its preview fails.
            const LeaveTypeOption(id: 'lt-gone', name: 'Study', paid: true),
          ],
          preview: preview,
          onSubmit: (result) async {
            submitted = result;
            return true;
          },
          failureMessage: null,
          request: leaveRequest(
            startDate: DateTime(2026, 12, 1),
            endDate: DateTime(2026, 12, 1),
          ),
        ),
      );
      await tester.tap(find.text('Annual leave').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Study').last);
      await tester.pumpAndSettle();

      expect(find.text('Leave type not found.'), findsOneWidget);

      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(submitted?.draft.leaveTypeId, 'lt-gone');
    });

    testWidgets('review dialog shows the paid/unpaid summary', (tester) async {
      final access = orgAdminAccess();
      final preview = previewFor(access);
      addTearDown(preview.dispose);
      final request = dataSource.requests.firstWhere((r) => r.id == 'LV-001');

      await pumpDialog(
        tester,
        LeaveReviewDialog(
          request: request,
          decision: LeaveStatus.approved,
          preview: preview,
          onSubmit: (_) async => true,
          failureMessage: null,
        ),
      );

      expect(
        find.textContaining('Sarah Connor · Annual leave'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Annual leave: 12 days available · 2 working days requested '
          '— 2 paid.',
        ),
        findsOneWidget,
      );
    });
  });
}
