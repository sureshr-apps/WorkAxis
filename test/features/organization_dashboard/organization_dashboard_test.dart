import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/features/organization_dashboard/data/mock_organization_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/presentation/controllers/organization_dashboard_controller.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/organization_home_screen.dart';

void main() {
  group('Organization Dashboard Repository & Controller', () {
    test('MockOrganizationDashboardRepository returns valid summary', () async {
      final repo = MockOrganizationDashboardRepository(delay: Duration.zero);
      final summary = await repo.getOrganizationDashboardSummary();

      expect(summary.attendance.present, equals(389));
      expect(summary.attendance.totalScheduled, equals(428));
      expect(summary.pendingReturns, equals(15));
      expect(summary.totalEmployees, equals(428));
      expect(summary.totalBranches, equals(14));
      expect(summary.attentionItems.isNotEmpty, isTrue);
    });

    test('OrganizationDashboardController updates state on load', () async {
      final repo = MockOrganizationDashboardRepository(delay: Duration.zero);
      final controller = OrganizationDashboardController(repository: repo);

      expect(controller.status, equals(OrganizationDashboardStatus.initial));
      await controller.loadDashboard();

      expect(controller.status, equals(OrganizationDashboardStatus.loaded));
      expect(controller.summary?.attendance.present, equals(389));
    });
  });

  group('OrganizationHomeScreen Widget Tests', () {
    testWidgets('renders Organization Overview header and KPI carousel', (
      tester,
    ) async {
      final repo = MockOrganizationDashboardRepository(delay: Duration.zero);
      final controller = OrganizationDashboardController(repository: repo);
      await controller.loadDashboard();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrganizationDashboardController>.value(
            value: controller,
            child: const OrganizationHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header (Stitch Display-LG headline)
      expect(find.text('Organization Overview'), findsOneWidget);

      // Verify NO organization switcher is rendered
      expect(find.text('Switch Organization'), findsNothing);
      expect(find.text('Change Organization'), findsNothing);

      // Verify KPI Concepts
      expect(find.text('Present Today'), findsOneWidget);
      expect(find.text("Today's Attendance"), findsOneWidget);
      expect(find.text('Total Staff'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);

      // Verify attendance breakdown pills
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('On Leave'), findsOneWidget);
    });

    testWidgets('renders cleanly on smartphone (390x844) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockOrganizationDashboardRepository(delay: Duration.zero);
      final controller = OrganizationDashboardController(repository: repo);
      await controller.loadDashboard();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrganizationDashboardController>.value(
            value: controller,
            child: const OrganizationHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Organization Overview'), findsOneWidget);
      expect(find.text("Today's Attendance"), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet (768x1024) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockOrganizationDashboardRepository(delay: Duration.zero);
      final controller = OrganizationDashboardController(repository: repo);
      await controller.loadDashboard();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrganizationDashboardController>.value(
            value: controller,
            child: const OrganizationHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Organization Overview'), findsOneWidget);
      expect(find.text("Today's Attendance"), findsOneWidget);
    });
  });
}
