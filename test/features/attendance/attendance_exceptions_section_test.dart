import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_exceptions_repository.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_exceptions_repository.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/correction_review_tile.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/overtime_review_tile.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

import '../../helpers/attendance_router.dart';
import '../../helpers/fixed_clock.dart';

void main() {
  late AccessController accessController;
  late BranchContextController branchController;
  late AttendanceController attendanceController;

  setUp(() {
    accessController = AccessController(
      accessRepository: MockAccessRepository(
        dataSource: MockAccessDataSource(),
        delay: Duration.zero,
      ),
    );
    branchController = BranchContextController();
    attendanceController = AttendanceController(
      repository: MockAttendanceRepository(now: fixedNow),
      now: fixedNow,
    );
  });

  tearDown(() {
    accessController.dispose();
    branchController.dispose();
    attendanceController.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    required UserRole role,
    required String userId,
    String? branchId,
    double width = 1200,
  }) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await accessController.resolveAccess(
      AppUser(
        id: userId,
        name: 'Reviewer',
        username: userId,
        role: role,
        organizationId: 'org-acme',
      ),
    );
    final access = accessController.accessContext!;
    branchController.initFromAccessContext(access);
    if (branchId != null) {
      branchController.selectBranch(
        access.assignedBranches.firstWhere((b) => b.id == branchId),
      );
    }
    final router = buildAttendanceRouter(role);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessController>.value(
            value: accessController,
          ),
          ChangeNotifierProvider<BranchContextController>.value(
            value: branchController,
          ),
          ChangeNotifierProvider<AttendanceController>.value(
            value: attendanceController,
          ),
          Provider<OrganizationMembersRepository>.value(
            value: MockOrganizationMembersRepository(),
          ),
          Provider<AttendanceExceptionsRepository>.value(
            value: MockAttendanceExceptionsRepository(now: fixedNow),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inDialog(String text) =>
      find.descendant(of: find.byType(Dialog), matching: find.text(text));

  testWidgets('Org Admin approves a check-out correction with a note', (
    tester,
  ) async {
    await pump(tester, role: UserRole.orgAdmin, userId: 'user-oa-01');

    expect(find.text('Exceptions to review'), findsOneWidget);
    expect(find.text('Check-out corrections (1)'), findsOneWidget);
    expect(find.text('Overtime approvals (1)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CorrectionReviewTile),
        matching: find.text('Mina Patel'),
      ),
      findsOneWidget,
    );
    expect(find.text('Requested check-out'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(CorrectionReviewTile),
        matching: find.text('Approve'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Approve correction?'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      'Confirmed with the shift lead',
    );
    await tester.tap(inDialog('Approve'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Check-out correction approved.'), findsOneWidget);
    expect(find.text('Check-out corrections (0)'), findsOneWidget);
    expect(find.text('No check-out corrections waiting.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overtime hours are validated against the potential', (
    tester,
  ) async {
    await pump(tester, role: UserRole.orgAdmin, userId: 'user-oa-01');

    expect(find.text('2h potential OT'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(OvertimeReviewTile),
        matching: find.text('Approve'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Approve overtime?'), findsOneWidget);

    final field = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(field).controller!.text, '2');

    await tester.enterText(field, '3');
    await tester.pump();
    expect(find.text('At most 2h (the potential overtime).'), findsOneWidget);

    await tester.tap(inDialog('Approve'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.enterText(field, '1.5');
    await tester.tap(inDialog('Approve'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Overtime approved.'), findsOneWidget);
    expect(find.text('Overtime approvals (0)'), findsOneWidget);
  });

  testWidgets('rejecting overtime asks for confirmation', (tester) async {
    await pump(tester, role: UserRole.orgAdmin, userId: 'user-oa-01');

    await tester.tap(
      find.descendant(
        of: find.byType(OvertimeReviewTile),
        matching: find.text('Reject'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reject overtime?'), findsOneWidget);

    await tester.tap(inDialog('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Overtime approvals (1)'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(OvertimeReviewTile),
        matching: find.text('Reject'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(inDialog('Reject'));
    await tester.pumpAndSettle();
    expect(find.text('Overtime rejected.'), findsOneWidget);
    expect(find.text('Overtime approvals (0)'), findsOneWidget);
  });

  testWidgets('Branch Manager lists follow the active branch', (tester) async {
    await pump(
      tester,
      role: UserRole.branchManager,
      userId: 'user-bm-multi-01',
      branchId: 'br-01',
    );
    expect(find.text('Check-out corrections (1)'), findsOneWidget);

    branchController.selectBranch(
      accessController.accessContext!.assignedBranches.firstWhere(
        (b) => b.id == 'br-02',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CorrectionReviewTile), findsNothing);
    expect(find.text('Check-out corrections (0)'), findsOneWidget);
    expect(find.text('Overtime approvals (0)'), findsOneWidget);
  });

  testWidgets('employees never see the review section', (tester) async {
    await pump(
      tester,
      role: UserRole.employee,
      userId: 'user-emp-01',
      width: 768,
    );
    expect(find.text('Exceptions to review'), findsNothing);
  });

  testWidgets('stacks both lists on a phone without overflow', (tester) async {
    await pump(
      tester,
      role: UserRole.orgAdmin,
      userId: 'user-oa-01',
      width: 390,
    );
    final corrections = tester.getTopLeft(
      find.text('Check-out corrections (1)'),
    );
    final overtime = tester.getTopLeft(find.text('Overtime approvals (1)'));
    expect(overtime.dy, greaterThan(corrections.dy));
    expect(tester.takeException(), isNull);
  });
}
