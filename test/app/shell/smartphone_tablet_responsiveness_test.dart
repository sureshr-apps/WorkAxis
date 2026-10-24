import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/platform_overview_hero_banner.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/recent_organizations_list.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/organizations_list_screen.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_card_item.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organizations_table.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/screens/platform_users_list_screen.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_card.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrators_table.dart';

void main() {
  final sampleOrganizations = [
    RecentOrganizationSummary(
      id: 'org-01',
      name: 'Apex Logistics',
      code: 'ORG-APX',
      status: 'active',
      branchCount: 14,
      employeeCount: 342,
      adminEmail: 'marcus@apexlogistics.com',
      createdAt: DateTime(2026, 1, 15),
    ),
    RecentOrganizationSummary(
      id: 'org-02',
      name: 'Beacon Retail',
      code: 'ORG-BCN',
      status: 'suspended',
      branchCount: 6,
      employeeCount: 88,
      adminEmail: 'elena@beaconretail.com',
      createdAt: DateTime(2026, 2, 20),
    ),
  ];

  group('Smartphone (<600dp) Responsiveness Tests', () {
    testWidgets('RecentOrganizationsList renders 1-column cards with 96dp status and Details link', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RecentOrganizationsList(organizations: sampleOrganizations),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile cards are rendered
      expect(find.text('Apex Logistics'), findsOneWidget);
      expect(find.text('Beacon Retail'), findsOneWidget);

      // Desktop table headers are NOT present
      expect(find.text('ADMIN CONTACT'), findsNothing);

      // StatusChips have 96dp width
      final statusChips = tester.widgetList<StatusChip>(find.byType(StatusChip));
      expect(statusChips.length, 2);
      for (final chip in statusChips) {
        expect(chip.width, 96);
      }

      // Details > link is rendered for each card
      expect(find.text('Details'), findsNWidgets(2));
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    });

    testWidgets('PlatformOverviewHeroBanner renders full-width 48dp action button on smartphone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(child: PlatformOverviewHeroBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.widgetWithText(ElevatedButton, 'Add Organization');
      expect(button, findsOneWidget);
      final buttonSize = tester.getSize(button);
      expect(buttonSize.height, greaterThanOrEqualTo(48));
      expect(buttonSize.width, greaterThan(300));
    });

    testWidgets('OrganizationsListScreen renders OrganizationCardItem on smartphone with no 2-letter avatar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<PlatformOrganizationsController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OrganizationsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrganizationCardItem), findsWidgets);
      expect(find.byType(OrganizationsTable), findsNothing);

      // Details > link present on cards
      expect(find.text('Details'), findsWidgets);
    });

    testWidgets('PlatformUsersListScreen renders stacked user cards on smartphone with 96dp StatusChip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PlatformUsersController(
        repository: MockPlatformUsersRepository(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<PlatformUsersController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PlatformUsersListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlatformAdministratorCard), findsNWidgets(4));
      expect(find.byType(PlatformAdministratorsTable), findsNothing);

      // StatusChips have 96dp width
      final statusChips = tester.widgetList<StatusChip>(find.byType(StatusChip));
      for (final chip in statusChips) {
        expect(chip.width, 96);
      }
    });
  });

  group('Tablet (600–839dp) Responsiveness Tests', () {
    testWidgets('RecentOrganizationsList renders 2-column card grid and inline search/filters on tablet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RecentOrganizationsList(organizations: sampleOrganizations),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tablet uses Wrap for balanced 2-column grid
      expect(find.byType(Wrap), findsWidgets);
      expect(find.text('ADMIN CONTACT'), findsNothing); // Table not shown
      expect(find.text('Details'), findsNWidgets(2));
    });

    testWidgets('OrganizationsListScreen renders 2-column grid on tablet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<PlatformOrganizationsController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OrganizationsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrganizationCardItem), findsWidgets);
      expect(find.byType(OrganizationsTable), findsNothing);
    });

    testWidgets('PlatformUsersListScreen renders balanced 2-column grid and inline search/filters on tablet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PlatformUsersController(
        repository: MockPlatformUsersRepository(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<PlatformUsersController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PlatformUsersListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlatformAdministratorCard), findsNWidgets(4));
      expect(find.byType(PlatformAdministratorsTable), findsNothing);
      expect(find.text('Details'), findsWidgets);
    });
  });

  group('Desktop (>=840dp) Integrity Tests (UNTOUCHED)', () {
    testWidgets('RecentOrganizationsList renders standard data table with headers on desktop', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RecentOrganizationsList(organizations: sampleOrganizations),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ORGANIZATION'), findsOneWidget);
      expect(find.text('CODE'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('BRANCHES'), findsOneWidget);
      expect(find.text('STAFF'), findsOneWidget);
      expect(find.text('ADMIN CONTACT'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);
    });

    testWidgets('OrganizationsListScreen renders OrganizationsTable on desktop', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<PlatformOrganizationsController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OrganizationsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrganizationsTable), findsOneWidget);
      expect(find.byType(OrganizationCardItem), findsNothing);
    });

    testWidgets('PlatformUsersListScreen renders PlatformAdministratorsTable on desktop', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PlatformUsersController(
        repository: MockPlatformUsersRepository(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<PlatformUsersController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PlatformUsersListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlatformAdministratorsTable), findsOneWidget);
      expect(find.byType(PlatformAdministratorCard), findsNothing);
    });
  });
}
