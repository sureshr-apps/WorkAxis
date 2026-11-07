import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/features/platform_dashboard/data/mock_platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';
import 'package:workaxis/features/platform_dashboard/presentation/controllers/platform_dashboard_controller.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/platform_home_screen.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/recent_organizations/recent_organizations_filter.dart';

RecentOrganizationSummary _org(String name, String code, String status) =>
    RecentOrganizationSummary(
      id: code,
      name: name,
      code: code,
      status: status,
      branchCount: 1,
      employeeCount: 2,
      createdAt: DateTime(2026, 1, 15),
    );

void main() {
  group('filterRecentOrganizations', () {
    final orgs = [
      _org('Acme', 'ORG-A', 'active'),
      _org('Beta Foods', 'ORG-B', 'suspended'),
      _org('Gamma', 'ORG-G', 'active'),
    ];

    test('filters by status and by name or code, case-insensitively', () {
      expect(
        filterRecentOrganizations(
          orgs,
          filter: RecentOrganizationsFilter.suspended,
          query: '',
        ).map((o) => o.name),
        ['Beta Foods'],
      );
      expect(
        filterRecentOrganizations(
          orgs,
          filter: RecentOrganizationsFilter.all,
          query: ' org-g ',
        ).map((o) => o.name),
        ['Gamma'],
      );
      expect(
        filterRecentOrganizations(
          orgs,
          filter: RecentOrganizationsFilter.active,
          query: 'beta',
        ),
        isEmpty,
      );
    });
  });

  group('PlatformHomeScreen', () {
    Future<PlatformDashboardController> pump(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = PlatformDashboardController(
        repository: MockPlatformDashboardRepository(delay: Duration.zero),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PlatformDashboardController>.value(
            value: controller,
            child: const PlatformHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('reloads on entry even when the controller already loaded', (
      tester,
    ) async {
      final repository = _CountingRepository();
      final controller = PlatformDashboardController(repository: repository);
      addTearDown(controller.dispose);
      await controller.loadDashboard();
      expect(repository.summaryLoads, 1);

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PlatformDashboardController>.value(
            value: controller,
            child: const PlatformHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.summaryLoads, 2);
    });

    testWidgets('search narrows the recent organizations', (tester) async {
      await pump(tester, const Size(1280, 900));

      await tester.enterText(find.byType(TextField), 'crestline');
      await tester.pumpAndSettle();
      expect(find.text('Crestline Cold Storage'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz-no-match');
      await tester.pumpAndSettle();
      expect(find.text('No matching organizations.'), findsOneWidget);
    });

    for (final size in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1280, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width.toInt()}dp', (
        tester,
      ) async {
        await pump(tester, size);
        expect(find.text('Recent Organizations'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

class _CountingRepository extends MockPlatformDashboardRepository {
  _CountingRepository() : super(delay: Duration.zero);

  int summaryLoads = 0;

  @override
  Future<PlatformDashboardSummary> getPlatformDashboardSummary() {
    summaryLoads++;
    return super.getPlatformDashboardSummary();
  }
}
