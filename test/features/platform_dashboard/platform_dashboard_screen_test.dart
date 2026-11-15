import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/features/platform_dashboard/data/mock_platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_filter.dart';
import 'package:workaxis/features/platform_dashboard/presentation/controllers/platform_dashboard_controller.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/platform_home_screen.dart';

CustomerOrganization _org(
  String name,
  String code,
  OrganizationStatus status,
) => CustomerOrganization(
  id: code,
  name: name,
  code: code,
  status: status,
  branchCount: 1,
  employeeCount: 2,
  createdAt: DateTime(2026, 1, 15),
);

void main() {
  group('filterOrganizations', () {
    final orgs = [
      _org('Acme', 'ORG-A', OrganizationStatus.active),
      _org('Beta Foods', 'ORG-B', OrganizationStatus.suspended),
      _org('Gamma', 'ORG-G', OrganizationStatus.active),
    ];

    test('filters by status and by name or code, case-insensitively', () {
      expect(
        filterOrganizations(
          orgs,
          status: OrganizationStatus.suspended,
        ).map((o) => o.name),
        ['Beta Foods'],
      );
      expect(filterOrganizations(orgs, query: ' org-g ').map((o) => o.name), [
        'Gamma',
      ]);
      expect(
        filterOrganizations(
          orgs,
          status: OrganizationStatus.active,
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
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Crestline Cold Storage'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz-no-match');
      await tester.pump(const Duration(milliseconds: 400));
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
