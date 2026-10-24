import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/platform_dashboard/data/mock_platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/presentation/controllers/platform_dashboard_controller.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/platform_home_screen.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';

void main() {
  group('Platform Dashboard Repository & Controller', () {
    test('MockPlatformDashboardRepository returns correct summary and organizations', () async {
      final repo = MockPlatformDashboardRepository(delay: Duration.zero);
      final summary = await repo.getPlatformDashboardSummary();
      final orgs = await repo.getRecentOrganizations();

      expect(summary.totalOrganizations, equals(7));
      expect(summary.activeOrganizations, equals(5));
      expect(summary.suspendedOrganizations, equals(2));
      expect(summary.platformAdminsCount, equals(4));

      expect(orgs.length, equals(4));
      expect(orgs.first.name, equals('Crestline Cold Storage'));
      expect(orgs.first.code, equals('ORG-CCS-77'));
      expect(orgs.first.adminEmail, equals('ops@crestlinecold.com'));
      expect(orgs.first.status, equals('suspended'));
    });

    test('PlatformDashboardController loads summary into state', () async {
      final repo = MockPlatformDashboardRepository(delay: Duration.zero);
      final controller = PlatformDashboardController(repository: repo);

      expect(controller.status, equals(PlatformDashboardStatus.initial));
      await controller.loadDashboard();

      expect(controller.status, equals(PlatformDashboardStatus.loaded));
      expect(controller.summary, isNotNull);
      expect(controller.summary?.totalOrganizations, equals(7));
      expect(controller.summary?.activeOrganizations, equals(5));
      expect(controller.summary?.suspendedOrganizations, equals(2));
      expect(controller.recentOrganizations.length, equals(4));
    });
  });

  group('PlatformHomeScreen Widget Tests', () {
    testWidgets(
      'renders Platform Overview header, KPI cards, and organizations',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = MockPlatformDashboardRepository(delay: Duration.zero);
        final controller = PlatformDashboardController(repository: repo);
        await controller.loadDashboard();

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<PlatformDashboardController>.value(
              value: controller,
              child: const PlatformHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Platform Overview'), findsOneWidget);
        expect(find.text('Total Organizations'), findsOneWidget);
        expect(find.text('Active Organizations'), findsOneWidget);
        expect(find.text('Suspended Organizations'), findsOneWidget);
        expect(find.text('Platform Administrators'), findsOneWidget);
        expect(find.text('Recent Organizations'), findsOneWidget);
        expect(find.text('Crestline Cold Storage'), findsOneWidget);
        expect(find.text('ORG-CCS-77'), findsOneWidget);

        // Verify Fleet Operational label is removed
        expect(find.text('Fleet Operational'), findsNothing);

        // Verify caption below Recent Organizations is removed
        expect(
          find.text('Customer organizations provisioned on this platform'),
          findsNothing,
        );

        // Verify CODE column header is present in the table
        expect(find.text('CODE'), findsOneWidget);

        // Verify View All action is present at bottom of section
        expect(find.text('View All'), findsOneWidget);

        // Verify KPI supporting footers are removed
        expect(find.text('Nationwide customer fleet'), findsNothing);
        expect(find.text('Operational & verified'), findsNothing);
        expect(find.text('Action required or paused'), findsNothing);
        expect(find.text('Active console operators'), findsNothing);

        // Verify KPI badges (71.4% and Requires triage) are removed
        expect(find.text('71.4%'), findsNothing);
        expect(find.text('Requires triage'), findsNothing);

        // Verify StatusChip in the table has uniform width
        final statusChips = tester.widgetList<StatusChip>(find.byType(StatusChip));
        expect(statusChips, isNotEmpty);
        for (final chip in statusChips) {
          expect(chip.width, equals(96.0));
        }

        // Verify obsolete subscription/billing metrics are completely removed
        expect(find.text('Active Subscriptions'), findsNothing);
        expect(find.text('Monthly Recurring Revenue'), findsNothing);
        expect(find.text('MRR'), findsNothing);
      },
    );
  });

  group('Platform Organizations and Overview Synchronized Mock Data', () {
    late MockPlatformOrganizationsDataSource sharedDataSource;
    late MockPlatformOrganizationsRepository orgsRepo;
    late MockPlatformDashboardRepository dashboardRepo;

    setUp(() {
      sharedDataSource = MockPlatformOrganizationsDataSource();
      orgsRepo = MockPlatformOrganizationsRepository(
        dataSource: sharedDataSource,
      );
      dashboardRepo = MockPlatformDashboardRepository(
        organizationsDataSource: sharedDataSource,
        delay: Duration.zero,
      );
    });

    test('createOrganization updates dashboard summary counts and prepends to recent list', () async {
      final initialSummary = await dashboardRepo.getPlatformDashboardSummary();
      final initialRecent = await dashboardRepo.getRecentOrganizations();

      expect(initialSummary.totalOrganizations, equals(7));
      expect(initialSummary.activeOrganizations, equals(5));
      expect(initialSummary.suspendedOrganizations, equals(2));
      expect(initialRecent.length, equals(4));

      final newOrg = CreateOrganizationRequest(
        name: 'Quantum Logistics',
        taxIdentification: 'US-EIN-56-7890123',
        contactName: 'Sarah Connor',
        contactEmail: 's.connor@quantumlogistics.com',
      );

      await orgsRepo.createOrganization(newOrg);

      final updatedSummary = await dashboardRepo.getPlatformDashboardSummary();
      final updatedRecent = await dashboardRepo.getRecentOrganizations();

      expect(updatedSummary.totalOrganizations, equals(8));
      expect(updatedSummary.activeOrganizations, equals(6));
      expect(updatedSummary.suspendedOrganizations, equals(2));
      expect(updatedSummary.platformAdminsCount, equals(4));

      // Recent list size is kept at 4, ordered newest createdAt first
      expect(updatedRecent.length, equals(4));
      expect(updatedRecent.first.id, equals('org-generated-001'));
      expect(updatedRecent.first.name, equals('Quantum Logistics'));
      expect(updatedRecent.first.code, equals('ORG-001'));
      expect(
        updatedRecent.first.adminEmail,
        equals('s.connor@quantumlogistics.com'),
      );
      expect(updatedRecent.first.status, equals('active'));
      expect(updatedRecent.first.branchCount, equals(0));
      expect(updatedRecent.first.employeeCount, equals(0));
    });

    test('updateOrganization updates organization details in dashboard recent list', () async {
      // Crestline Cold Storage is in the initial recent list
      final initialRecent = await dashboardRepo.getRecentOrganizations();
      final crestline = initialRecent.firstWhere(
        (o) => o.id == 'org-crestline',
      );
      expect(crestline.name, equals('Crestline Cold Storage'));

      final currentRecord = await orgsRepo.getOrganizationById('org-crestline');
      expect(currentRecord, isNotNull);

      final updatedRecord = currentRecord!.copyWith(
        name: 'Crestline Cold Chain Solutions',
        code: 'ORG-CCS-99',
        contactEmail: 'dispatch@crestlinecoldchain.com',
        branchCount: 12,
        employeeCount: 220,
      );

      await orgsRepo.updateOrganization(updatedRecord);

      final refreshedRecent = await dashboardRepo.getRecentOrganizations();
      final updatedRecentItem = refreshedRecent.firstWhere(
        (o) => o.id == 'org-crestline',
      );

      expect(updatedRecentItem.name, equals('Crestline Cold Chain Solutions'));
      expect(updatedRecentItem.code, equals('ORG-CCS-99'));
      expect(
        updatedRecentItem.adminEmail,
        equals('dispatch@crestlinecoldchain.com'),
      );
      expect(updatedRecentItem.branchCount, equals(12));
      expect(updatedRecentItem.employeeCount, equals(220));
    });

    test('updateOrganizationStatus reflects in active/suspended counts and recent list status', () async {
      // Suspend ABC Enterprises Global (originally active)
      final summaryBefore = await dashboardRepo.getPlatformDashboardSummary();
      expect(summaryBefore.activeOrganizations, equals(5));
      expect(summaryBefore.suspendedOrganizations, equals(2));

      await orgsRepo.updateOrganizationStatus(
        'org-abc',
        OrganizationStatus.suspended,
      );

      final summaryAfterSuspend = await dashboardRepo
          .getPlatformDashboardSummary();
      expect(summaryAfterSuspend.activeOrganizations, equals(4));
      expect(summaryAfterSuspend.suspendedOrganizations, equals(3));
      expect(summaryAfterSuspend.totalOrganizations, equals(7));

      final recentAfterSuspend = await dashboardRepo.getRecentOrganizations();
      final abcRecent = recentAfterSuspend.firstWhere((o) => o.id == 'org-abc');
      expect(abcRecent.status, equals('suspended'));
      expect(abcRecent.isActive, isFalse);

      // Reactivate Crestline Cold Storage (originally suspended)
      await orgsRepo.updateOrganizationStatus(
        'org-crestline',
        OrganizationStatus.active,
      );

      final summaryAfterReactivate = await dashboardRepo
          .getPlatformDashboardSummary();
      expect(summaryAfterReactivate.activeOrganizations, equals(5));
      expect(summaryAfterReactivate.suspendedOrganizations, equals(2));

      final recentAfterReactivate = await dashboardRepo
          .getRecentOrganizations();
      final crestlineRecent = recentAfterReactivate.firstWhere(
        (o) => o.id == 'org-crestline',
      );
      expect(crestlineRecent.status, equals('active'));
      expect(crestlineRecent.isActive, isTrue);
    });

    test('WorkAxisApp default repositories share one MockPlatformOrganizationsDataSource instance', () {
      final app = WorkAxisApp(
        authRepository: MockAuthenticationRepository(delay: Duration.zero),
        accessRepository: MockAccessRepository(delay: Duration.zero),
      );

      expect(app.platformRepository, isA<MockPlatformDashboardRepository>());
      expect(
        app.platformOrganizationsRepository,
        isA<MockPlatformOrganizationsRepository>(),
      );

      final dashboard =
          app.platformRepository as MockPlatformDashboardRepository;
      final orgs =
          app.platformOrganizationsRepository
              as MockPlatformOrganizationsRepository;

      expect(
        dashboard.dataSource.organizationsDataSource,
        same(orgs.dataSource),
      );
    });

    test('WorkAxisApp preserves explicit repository injection', () {
      final customDashboardRepo = MockPlatformDashboardRepository(
        delay: Duration.zero,
      );
      final customOrgsRepo = MockPlatformOrganizationsRepository();

      final app = WorkAxisApp(
        authRepository: MockAuthenticationRepository(delay: Duration.zero),
        accessRepository: MockAccessRepository(delay: Duration.zero),
        platformRepository: customDashboardRepo,
        platformOrganizationsRepository: customOrgsRepo,
      );

      expect(app.platformRepository, same(customDashboardRepo));
      expect(app.platformOrganizationsRepository, same(customOrgsRepo));
    });
  });
}
