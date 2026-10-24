import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/employee_home/data/mock_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';
import 'package:workaxis/features/employee_home/presentation/screens/employee_home_screen.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/active_geofence_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/attendance_summary_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/employee_returns_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/hero_attendance_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/safety_notices_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/today_assignment_card.dart';

void main() {
  group('Employee Home Repository & Controller', () {
    test(
      'MockEmployeeHomeRepository returns initial checked in summary matching Stitch',
      () async {
        final repo = MockEmployeeHomeRepository(delay: Duration.zero);
        final summary = await repo.getEmployeeHomeSummary();

        expect(summary.employeeName, equals('Marcus Vance'));
        expect(summary.branchName, equals('Central Distribution Hub'));
        expect(summary.currentStatus, equals(AttendanceStatus.checkedIn));
        expect(summary.checkInTime, equals('07:54 AM'));
        expect(summary.pendingReturnsCount, equals(1));
        expect(summary.approvedReturnsCount, equals(4));
        expect(
          summary.recentReturnTitle,
          equals('Safety Helmet & High-Vis Vest Replacement'),
        );
        expect(
          summary.recentReturnStatus,
          equals('Pending Approval'),
        );
      },
    );

    test('EmployeeHomeController records attendance action', () async {
      final repo = MockEmployeeHomeRepository(delay: Duration.zero);
      final controller = EmployeeHomeController(repository: repo);

      await controller.loadHomeSummary();
      expect(
        controller.summary?.currentStatus,
        equals(AttendanceStatus.checkedIn),
      );

      // Perform next suggested action (Start Break)
      await controller.performNextAttendanceAction();
      expect(
        controller.summary?.currentStatus,
        equals(AttendanceStatus.onBreak),
      );
    });

    test('EmployeeHomeController sets simulated status', () async {
      final repo = MockEmployeeHomeRepository(delay: Duration.zero);
      final controller = EmployeeHomeController(repository: repo);

      await controller.loadHomeSummary();
      await controller.setSimulatedStatus(AttendanceStatus.notCheckedIn);
      expect(
        controller.summary?.currentStatus,
        equals(AttendanceStatus.notCheckedIn),
      );
      expect(controller.summary?.checkInTime, equals('-- : --'));
    });
  });

  group('EmployeeHomeScreen Widget Tests', () {
    testWidgets(
      'renders Employee Home matching Stitch design with telemetry, assignment, returns, and safety notices',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = MockEmployeeHomeRepository(delay: Duration.zero);
        final controller = EmployeeHomeController(repository: repo);
        await controller.loadHomeSummary();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: ChangeNotifierProvider<EmployeeHomeController>.value(
              value: controller,
              child: const EmployeeHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify Sub-Header Bar & Badges
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('CH-001'), findsOneWidget);
        expect(
          find.text('Location ready • Inside Branch Geofence'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Marcus Vance • Apex Logistics & Freight'),
          findsOneWidget,
        );

        // 2. Verify Simulation Controls
        expect(find.text('Not Checked In'), findsWidgets);
        expect(find.text('Checked In (Active)'), findsOneWidget);
        expect(find.text('On Break'), findsOneWidget);
        expect(find.text('Shift Completed'), findsOneWidget);

        // 3. Verify Hero Attendance Card
        expect(find.byType(HeroAttendanceCard), findsOneWidget);
        expect(
          find.text('Morning Shift • 08:00 AM – 05:00 PM'),
          findsOneWidget,
        );
        expect(find.text('07:54 AM'), findsOneWidget);
        expect(find.text('Early 6m'), findsOneWidget);
        expect(find.text('5h 42m'), findsWidgets);
        expect(find.text('71.2%'), findsOneWidget);
        expect(find.text('Start Break'), findsOneWidget);
        expect(
          find.textContaining('Terminal Verified #CH-TERM-09'),
          findsOneWidget,
        );

        // 4. Verify Active Geofence Telemetry Card
        expect(find.byType(ActiveGeofenceCard), findsOneWidget);
        expect(find.text('Active Geofence Telemetry'), findsOneWidget);
        expect(find.text('Signal Strong (5G Mesh)'), findsOneWidget);
        expect(
          find.text('Zone B • Outbound Logistics Corridor'),
          findsOneWidget,
        );
        expect(find.text('Active Anchor'), findsOneWidget);
        expect(find.text('B4:F2:79:A1:09'), findsOneWidget);
        expect(find.text('1000ms'), findsOneWidget);
        expect(find.text('NFC Verified'), findsOneWidget);

        // 5. Verify Today's Assignment Card
        expect(find.byType(TodayAssignmentCard), findsOneWidget);
        expect(find.text("Today's Assignment"), findsOneWidget);
        expect(find.text('Tier 1 Priority'), findsOneWidget);
        expect(find.text('BAY-SORT-04'), findsOneWidget);
        expect(find.text('Rajesh Kumar'), findsOneWidget);

        // 6. Verify Attendance Summary Card
        expect(find.byType(AttendanceSummaryCard), findsOneWidget);
        expect(find.text('Attendance Summary'), findsOneWidget);
        expect(find.text('98.2%'), findsOneWidget);
        expect(find.text('Target > 95% (Achieved)'), findsOneWidget);
        expect(find.text('View attendance history'), findsOneWidget);

        // 7. Verify My Returns Card
        expect(find.byType(EmployeeReturnsCard), findsOneWidget);
        expect(find.text('My Returns'), findsOneWidget);
        expect(find.text('1 Pending'), findsOneWidget);
        expect(find.text('4 Approved'), findsOneWidget);
        expect(
          find.text('Safety Helmet & High-Vis Vest Replacement'),
          findsOneWidget,
        );
        expect(find.text('Submit return'), findsOneWidget);
        expect(find.text('View returns'), findsOneWidget);

        // 8. Verify Reminders & Safety Notices Card
        expect(find.byType(SafetyNoticesCard), findsOneWidget);
        expect(find.text('Reminders & Safety Notices'), findsOneWidget);
        expect(
          find.text('Shift Check-Out Reminder (05:00 PM Today)'),
          findsOneWidget,
        );
        expect(find.text('Forklift Zone Active'), findsOneWidget);

        // 9. Interactive Action: Tap 'Start Break' button in Hero Card
        await tester.tap(find.text('Start Break'));
        await tester.pumpAndSettle();

        expect(find.text('On Meal Break'), findsOneWidget);
        expect(find.text('Resume Shift'), findsOneWidget);
      },
    );

    testWidgets('renders cleanly on smartphone (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockEmployeeHomeRepository(delay: Duration.zero);
      final controller = EmployeeHomeController(repository: repo);
      await controller.loadHomeSummary();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider<EmployeeHomeController>.value(
            value: controller,
            child: const EmployeeHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(HeroAttendanceCard), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet (768x1024) without overflow', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockEmployeeHomeRepository(delay: Duration.zero);
      final controller = EmployeeHomeController(repository: repo);
      await controller.loadHomeSummary();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider<EmployeeHomeController>.value(
            value: controller,
            child: const EmployeeHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(HeroAttendanceCard), findsOneWidget);
    });
  });
}
