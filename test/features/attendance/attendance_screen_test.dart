import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/attendance_operations_screen.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_card_item.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_table.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

void main() {
  late MockAccessDataSource accessDataSource;
  late MockAccessRepository accessRepository;
  late MockAttendanceRepository attendanceRepository;
  late AccessController accessController;
  late BranchContextController branchContextController;
  late AttendanceController attendanceController;

  setUp(() {
    accessDataSource = MockAccessDataSource();
    accessRepository = MockAccessRepository(
      dataSource: accessDataSource,
      delay: Duration.zero,
    );
    attendanceRepository = MockAttendanceRepository();
    accessController = AccessController(accessRepository: accessRepository);
    branchContextController = BranchContextController();
    attendanceController = AttendanceController(repository: attendanceRepository);
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
  }) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
          ChangeNotifierProvider<AccessController>.value(value: accessController),
          ChangeNotifierProvider<BranchContextController>.value(
            value: branchContextController,
          ),
          ChangeNotifierProvider<AttendanceController>.value(
            value: attendanceController,
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
    testWidgets('renders Organization Attendance with clean table and KPI tiles', (
      tester,
    ) async {
      await pumpAttendanceScreen(tester, role: UserRole.orgAdmin);

      // Verify title & subtitles
      expect(find.text('Organization Attendance'), findsOneWidget);
      expect(find.text('TIME & ATTENDANCE'), findsOneWidget);

      // Verify KPI titles
      expect(find.text('On time'), findsOneWidget);
      expect(find.text('Late arrivals'), findsOneWidget);
      expect(find.text('Needs review'), findsWidgets);

      // Verify AttendanceTable rendered
      expect(find.byType(AttendanceTable), findsOneWidget);

      // Verify Table Column Headers
      expect(find.text('EMPLOYEE'), findsOneWidget);
      expect(find.text('BRANCH / HUB'), findsOneWidget);
      expect(find.text('CHECK IN'), findsOneWidget);
      expect(find.text('CHECK OUT'), findsOneWidget);
      expect(find.text('METHOD'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('EXCEPTION & REVIEW'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);

      // Verify India Fleet indicator in Table Footer
      expect(find.text('Platform Fleet: '), findsOneWidget);
      expect(find.text('INDIA'), findsOneWidget);
      expect(find.text('Showing 6 attendance records'), findsOneWidget);
    });

    testWidgets('displays date selector with Today and Yesterday chips', (
      tester,
    ) async {
      await pumpAttendanceScreen(tester, role: UserRole.orgAdmin);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('renders 1-column AttendanceCardItem cards on smartphone', (
      tester,
    ) async {
      await pumpAttendanceScreen(tester, role: UserRole.orgAdmin, width: 390);

      expect(find.byType(AttendanceCardItem), findsWidgets);
      expect(find.byType(AttendanceTable), findsNothing);
      expect(find.text('Details'), findsWidgets);
    });

    testWidgets('renders 2-column balanced grid of AttendanceCardItem on tablet', (
      tester,
    ) async {
      await pumpAttendanceScreen(tester, role: UserRole.orgAdmin, width: 768);

      expect(find.byType(AttendanceCardItem), findsWidgets);
      expect(find.byType(AttendanceTable), findsNothing);
      expect(find.byType(Wrap), findsWidgets);
    });
  });
}
