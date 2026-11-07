import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/attendance_operations_screen.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_dialog.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

import '../../helpers/fixed_clock.dart';

void main() {
  late MockAccessDataSource accessDataSource;
  late MockAccessRepository accessRepository;
  late MockAttendanceRepository attendanceRepository;
  late MockOrganizationMembersRepository membersRepository;
  late AccessController accessController;
  late BranchContextController branchContextController;
  late AttendanceController attendanceController;

  setUp(() {
    accessDataSource = MockAccessDataSource();
    accessRepository = MockAccessRepository(
      dataSource: accessDataSource,
      delay: Duration.zero,
    );
    attendanceRepository = MockAttendanceRepository(now: fixedNow);
    membersRepository = MockOrganizationMembersRepository();
    accessController = AccessController(accessRepository: accessRepository);
    branchContextController = BranchContextController();
    attendanceController = AttendanceController(
      repository: attendanceRepository,
      now: fixedNow,
    );
  });

  tearDown(() {
    accessController.dispose();
    branchContextController.dispose();
    attendanceController.dispose();
  });

  group('Group Attendance Domain & Repository Tests', () {
    test(
      'rejects unauthorized employee role from recording group attendance',
      () async {
        await accessController.resolveAccess(
          const AppUser(
            id: 'user-emp-01',
            name: 'Sarah Connor',
            username: 'sarah.connor',
            role: UserRole.employee,
            organizationId: 'org-acme',
          ),
        );

        final access = accessController.accessContext!;
        final request = GroupAttendanceRequest(
          branchId: 'br-01',
          workDate: BusinessTime.today(fixedNow),
          checkInAt: testNow,
          attendees: const [
            GroupAttendanceAttendee(
              employeeId: 'user-emp-02',
              employeeName: 'Alex Chen',
            ),
          ],
        );

        expect(
          () => attendanceRepository.markGroupAttendance(
            access: access,
            request: request,
          ),
          throwsA(isA<AccessDeniedException>()),
        );
      },
    );

    test('successfully records group attendance for branch manager', () async {
      await accessController.resolveAccess(
        const AppUser(
          id: 'user-bm-multi-01',
          name: 'Marcus Chen',
          username: 'marcus.chen',
          role: UserRole.branchManager,
          organizationId: 'org-acme',
        ),
      );

      final access = accessController.accessContext!;
      final today = BusinessTime.today(fixedNow);
      final request = GroupAttendanceRequest(
        branchId: 'br-01',
        workDate: today,
        checkInAt: DateTime(today.year, today.month, today.day, 8, 30),
        shiftName: 'Morning Shift',
        attendees: const [
          GroupAttendanceAttendee(
            employeeId: 'user-emp-08',
            employeeName: 'Rita Gomez',
          ),
          GroupAttendanceAttendee(
            employeeId: 'user-emp-09',
            employeeName: 'Omar Haddad',
          ),
        ],
        note: 'Transit bus arrival',
      );

      final results = await attendanceRepository.markGroupAttendance(
        access: access,
        request: request,
      );

      expect(results.length, 2);
      expect(results.first.employeeName, 'Rita Gomez');
      expect(results.first.status, AttendanceStatus.present);
      expect(
        results.first.note,
        contains('Morning Shift: Transit bus arrival'),
      );

      final records = await attendanceRepository.getAttendance(
        access: access,
        date: today,
        activeBranchId: 'br-01',
      );
      expect(records.any((r) => r.employeeId == 'user-emp-08'), isTrue);
    });
  });

  group('Group Attendance Widget & Flow Tests', () {
    Future<void> pumpOperationsScreen(
      WidgetTester tester, {
      required UserRole role,
      String? branchId,
    }) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await accessController.resolveAccess(
        AppUser(
          id: role == UserRole.branchManager
              ? 'user-bm-multi-01'
              : (role == UserRole.orgAdmin ? 'user-oa-01' : 'user-emp-01'),
          name: 'Test User',
          username: 'test.user',
          role: role,
          organizationId: 'org-acme',
        ),
      );

      final access = accessController.accessContext;
      if (access != null) {
        branchContextController.initFromAccessContext(access);
        if (branchId != null) {
          final target = access.assignedBranches.firstWhere(
            (b) => b.id == branchId,
          );
          branchContextController.selectBranch(target);
        }
      }

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

    testWidgets('shows Group Check-In button for Org Admin but not Employee', (
      tester,
    ) async {
      // 1. Employee view
      await pumpOperationsScreen(tester, role: UserRole.employee);
      expect(find.text('Group Check-In'), findsNothing);

      // 2. Org Admin view
      await pumpOperationsScreen(tester, role: UserRole.orgAdmin);
      expect(find.text('Group Check-In'), findsOneWidget);
    });

    testWidgets(
      'opens GroupAttendanceDialog and records batch check-in end to end',
      (tester) async {
        await pumpOperationsScreen(
          tester,
          role: UserRole.branchManager,
          branchId: 'br-01',
        );

        // Everyone seeded for br-01 already has a check-in today, so add a
        // new employee who does not (group check-in never double-records).
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

        expect(find.text('Group Check-In'), findsOneWidget);
        await tester.tap(find.text('Group Check-In'));
        await tester.pumpAndSettle();

        // Verify dialog opened
        expect(find.byType(GroupAttendanceDialog), findsOneWidget);
        expect(find.text('Group Attendance Check-In'), findsOneWidget);
        expect(find.text('Personnel Roster'), findsOneWidget);

        // Verify roster loaded with members for br-01 (Sarah Connor, Alex Chen)
        expect(find.text('Sarah Connor'), findsWidgets);
        expect(find.text('Alex Chen'), findsWidgets);
        expect(find.text('Nora Fresh'), findsWidgets);

        // Tap Confirm Check-In button
        final confirmBtn = find.byWidgetPredicate(
          (w) => w is AppButton && w.text.startsWith('Confirm Check-In'),
        );
        expect(confirmBtn, findsOneWidget);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Verify dialog dismissed and success snackbar shown
        expect(find.byType(GroupAttendanceDialog), findsNothing);
        expect(
          find.text('Group attendance check-in recorded successfully.'),
          findsOneWidget,
        );
      },
    );
  });
}
