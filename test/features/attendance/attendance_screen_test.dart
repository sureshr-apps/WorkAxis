import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/attendance_operations_screen.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_card_item.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_table.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_dialog.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

import '../../helpers/fixed_clock.dart';

/// Reads delegate to the mock; every write fails, to exercise error surfacing.
class _FailingWritesRepository implements AttendanceRepository {
  _FailingWritesRepository(this._delegate);

  final AttendanceRepository _delegate;

  @override
  Future<List<AttendanceEntry>> getAttendance({
    required UserAccessContext access,
    required DateTime date,
    String? activeBranchId,
    String? employeeId,
  }) => _delegate.getAttendance(
    access: access,
    date: date,
    activeBranchId: activeBranchId,
    employeeId: employeeId,
  );

  @override
  Future<AttendanceEntry> reviewException({
    required UserAccessContext access,
    required String entryId,
    required String activeBranchId,
    required AttendanceReviewDecision decision,
  }) => throw Exception('raw backend failure');

  @override
  Future<List<AttendanceEntry>> markGroupAttendance({
    required UserAccessContext access,
    required GroupAttendanceRequest request,
  }) => throw Exception('raw backend failure');
}

void main() {
  late MockAccessDataSource accessDataSource;
  late MockAccessRepository accessRepository;
  late AccessController accessController;
  late BranchContextController branchContextController;
  late AttendanceController attendanceController;
  late MockOrganizationMembersRepository membersRepository;

  setUp(() {
    accessDataSource = MockAccessDataSource();
    accessRepository = MockAccessRepository(
      dataSource: accessDataSource,
      delay: Duration.zero,
    );
    accessController = AccessController(accessRepository: accessRepository);
    branchContextController = BranchContextController();
    membersRepository = MockOrganizationMembersRepository();
    attendanceController = AttendanceController(
      repository: MockAttendanceRepository(now: fixedNow),
      now: fixedNow,
    );
  });

  tearDown(() {
    accessController.dispose();
    branchContextController.dispose();
    attendanceController.dispose();
  });

  Future<void> pumpAttendanceScreen(
    WidgetTester tester, {
    required UserRole role,
    double width = 1200,
    AttendanceRepository? repository,
  }) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    if (repository != null) {
      attendanceController.dispose();
      attendanceController = AttendanceController(
        repository: repository,
        now: fixedNow,
      );
    }

    await accessController.resolveAccess(
      AppUser(
        id: 'user-oa-01',
        name: 'Jordan Lee',
        username: 'jordan.lee',
        role: role,
        organizationId: 'org-acme',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessController>.value(
            value: accessController,
          ),
          ChangeNotifierProvider<BranchContextController>.value(
            value: branchContextController,
          ),
          ChangeNotifierProvider<AttendanceController>.value(
            value: attendanceController,
          ),
          Provider<OrganizationMembersRepository>.value(
            value: membersRepository,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AttendanceOperationsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('AttendanceOperationsScreen Widget Tests', () {
    testWidgets('renders the table and KPI tiles on desktop', (tester) async {
      await pumpAttendanceScreen(tester, role: UserRole.orgAdmin);

      expect(find.text('Organization Attendance'), findsOneWidget);
      expect(find.text('TIME & ATTENDANCE'), findsOneWidget);
      expect(find.text('On time'), findsOneWidget);
      expect(find.text('Late arrivals'), findsOneWidget);
      expect(find.text('Needs review'), findsWidgets);
      expect(find.byType(AttendanceTable), findsOneWidget);

      for (final header in [
        'EMPLOYEE',
        'BRANCH / HUB',
        'CHECK IN',
        'CHECK OUT',
        'METHOD',
        'STATUS',
        'EXCEPTION & REVIEW',
        'ACTIONS',
      ]) {
        expect(find.text(header), findsOneWidget);
      }
      expect(find.text('Showing 6 attendance records'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('never renders fabricated fleet / region indicators', (
      tester,
    ) async {
      await pumpAttendanceScreen(tester, role: UserRole.orgAdmin);

      expect(find.textContaining('Platform Fleet'), findsNothing);
      expect(find.text('INDIA'), findsNothing);
    });

    testWidgets('displays date selector with Today and Yesterday chips', (
      tester,
    ) async {
      await pumpAttendanceScreen(tester, role: UserRole.orgAdmin);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Nov 7, 2026'), findsOneWidget);
    });

    testWidgets('renders 1-column cards on smartphone without overflow', (
      tester,
    ) async {
      await pumpAttendanceScreen(tester, role: UserRole.orgAdmin, width: 390);

      expect(find.byType(AttendanceCardItem), findsWidgets);
      expect(find.byType(AttendanceTable), findsNothing);
      expect(find.text('Details'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders 2-column cards on tablet without overflow', (
      tester,
    ) async {
      await pumpAttendanceScreen(tester, role: UserRole.orgAdmin, width: 768);

      expect(find.byType(AttendanceCardItem), findsWidgets);
      expect(find.byType(AttendanceTable), findsNothing);
      final first = tester.getTopLeft(find.byType(AttendanceCardItem).at(0));
      final second = tester.getTopLeft(find.byType(AttendanceCardItem).at(1));
      expect(second.dx, greaterThan(first.dx));
      expect(tester.takeException(), isNull);
    });

    testWidgets('employee view has no review or group check-in actions', (
      tester,
    ) async {
      await pumpAttendanceScreen(tester, role: UserRole.employee, width: 768);

      expect(find.text('My Attendance'), findsOneWidget);
      expect(find.text('Group Check-In'), findsNothing);
      expect(find.text('Verify'), findsNothing);
    });

    testWidgets('surfaces a failed review instead of ignoring it', (
      tester,
    ) async {
      await pumpAttendanceScreen(
        tester,
        role: UserRole.orgAdmin,
        repository: _FailingWritesRepository(
          MockAttendanceRepository(now: fixedNow),
        ),
      );

      await tester.tap(find.byTooltip('Verify attendance').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
        find.text('This attendance item could not be reviewed.'),
        findsOneWidget,
      );
      expect(find.textContaining('raw backend failure'), findsNothing);
    });

    testWidgets('keeps the group dialog open and shows why submit failed', (
      tester,
    ) async {
      await pumpAttendanceScreen(
        tester,
        role: UserRole.orgAdmin,
        repository: _FailingWritesRepository(
          MockAttendanceRepository(now: fixedNow),
        ),
      );
      await membersRepository.saveMember(
        access: accessController.accessContext!,
        activeBranchId: 'br-01',
        initialPassword: 'Temporary!123',
        member: const OrganizationMember(
          id: '',
          organizationId: 'org-acme',
          fullName: 'Nora Fresh',
          username: 'nora.fresh',
          email: 'nora.fresh@example.com',
          role: UserRole.employee,
          branchIds: ['br-01'],
          status: AccountStatus.active,
        ),
      );

      await tester.tap(find.text('Group Check-In'));
      await tester.pumpAndSettle();
      expect(find.byType(GroupAttendanceDialog), findsOneWidget);

      final confirm = find.byWidgetPredicate(
        (w) => w is AppButton && w.text.startsWith('Confirm Check-In'),
      );
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.byType(GroupAttendanceDialog), findsOneWidget);
      expect(
        find.text('Could not record group attendance. Try again.'),
        findsOneWidget,
      );
    });
  });
}
