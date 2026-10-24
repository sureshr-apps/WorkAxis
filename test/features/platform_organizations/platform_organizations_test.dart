import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/add_organization_screen.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/edit_organization_screen.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/organization_details_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/organizations_list_screen.dart';

void main() {
  group('PlatformOrganizations Repository & Controller Unit Tests', () {
    late MockPlatformOrganizationsRepository repository;
    late PlatformOrganizationsController controller;

    setUp(() {
      repository = MockPlatformOrganizationsRepository();
      controller = PlatformOrganizationsController(repository: repository);
    });

    test(
      'loads initial organizations with active and suspended counts',
      () async {
        await controller.loadOrganizations();

        expect(controller.totalCount, greaterThanOrEqualTo(6));
        expect(controller.activeCount, greaterThan(0));
        expect(controller.suspendedCount, greaterThan(0));
        expect(controller.organizations.length, controller.totalCount);
      },
    );

    test('filters organizations by search query (name or code)', () async {
      await controller.loadOrganizations();

      controller.setSearchQuery('Apex');
      expect(controller.organizations.length, 1);
      expect(controller.organizations.first.name, contains('Apex'));

      controller.setSearchQuery('ORG-ACM');
      expect(controller.organizations.length, 1);
      expect(controller.organizations.first.code, 'ORG-ACM-01');

      controller.setSearchQuery('NonExistentOrgName');
      expect(controller.organizations, isEmpty);
    });

    test('filters organizations by status filter', () async {
      await controller.loadOrganizations();

      controller.setStatusFilter(OrganizationStatus.active);
      expect(
        controller.organizations.every(
          (o) => o.status == OrganizationStatus.active,
        ),
        isTrue,
      );

      controller.setStatusFilter(OrganizationStatus.suspended);
      expect(
        controller.organizations.every(
          (o) => o.status == OrganizationStatus.suspended,
        ),
        isTrue,
      );

      controller.setStatusFilter(null);
      expect(controller.organizations.length, controller.totalCount);
    });

    test('creates organizations with generated identifiers', () async {
      await controller.loadOrganizations();
      final initialTotal = controller.totalCount;

      final request = CreateOrganizationRequest(
        name: 'Titan Freightways',
        taxIdentification: 'US-EIN-12-3456789',
      );

      final created = await controller.createOrganization(request);
      expect(created, isNotNull);
      expect(created?.name, 'Titan Freightways');
      expect(created?.id, 'org-generated-001');
      expect(created?.code, 'ORG-001');
      expect(created?.taxIdentification, 'US-EIN-12-3456789');
      expect(controller.totalCount, initialTotal + 1);

      final secondCreated = await controller.createOrganization(
        const CreateOrganizationRequest(name: 'Titan Duplicate'),
      );
      expect(secondCreated?.id, 'org-generated-002');
      expect(secondCreated?.code, 'ORG-002');
      expect(secondCreated?.taxIdentification, isNull);
      expect(
        await repository.getOrganizationLicenseDetails(secondCreated!.id),
        isNull,
      );
    });

    test('updates organization status (suspend and reactivate)', () async {
      await controller.loadOrganizations();

      // Suspend Acme Corporation
      final suspendedOk = await controller.updateStatus(
        'org-acme',
        OrganizationStatus.suspended,
      );
      expect(suspendedOk, isTrue);

      var acme = await repository.getOrganizationById('org-acme');
      expect(acme?.isSuspended, isTrue);

      // Reactivate Acme Corporation
      final reactivatedOk = await controller.updateStatus(
        'org-acme',
        OrganizationStatus.active,
      );
      expect(reactivatedOk, isTrue);

      acme = await repository.getOrganizationById('org-acme');
      expect(acme?.isActive, isTrue);
    });
  });

  group('OrganizationsListScreen Widget Tests', () {
    Widget buildTestWidget({
      required PlatformOrganizationsController controller,
      Size screenSize = const Size(1280, 800),
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<PlatformOrganizationsController>.value(
            value: controller,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: const OrganizationsListScreen(),
          ),
        ),
      );
    }

    testWidgets(
      'renders header, search bar, and organization items on desktop',
      (tester) async {
        final repository = MockPlatformOrganizationsRepository();
        final controller = PlatformOrganizationsController(
          repository: repository,
        );

        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestWidget(controller: controller));
        await tester.pumpAndSettle();

        expect(find.text('Organizations'), findsOneWidget);
        expect(find.text('Add Organization'), findsOneWidget);
        expect(find.text('Acme Corporation'), findsOneWidget);
        expect(find.text('Apex Logistics & Freight'), findsOneWidget);
        expect(find.text('ORGANIZATION'), findsOneWidget);
        expect(find.text('CODE'), findsOneWidget);
        expect(find.text('STATUS'), findsOneWidget);
      },
    );

    testWidgets('renders compact card list on smartphone screen', (
      tester,
    ) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          screenSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Organizations'), findsOneWidget);
      expect(find.text('Acme Corporation'), findsOneWidget);
      expect(find.text('hubs'), findsWidgets);
      expect(find.text('staff'), findsWidgets);
    });

    testWidgets('filters list by entering text in search box', (tester) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Apex');
      await tester.pumpAndSettle();

      expect(find.text('Apex Logistics & Freight'), findsOneWidget);
      expect(find.text('Acme Corporation'), findsNothing);
    });
  });

  group('OrganizationDetailsScreen Widget Tests', () {
    Widget buildDetailsTestWidget({
      required PlatformOrganizationsController controller,
      required String orgId,
      Size screenSize = const Size(1280, 900),
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<PlatformOrganizationsController>.value(
            value: controller,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: OrganizationDetailsScreen(organizationId: orgId),
          ),
        ),
      );
    }

    testWidgets('renders organization details, KPI cards, and admins list', (
      tester,
    ) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );
      await controller.loadOrganizationDetails('org-acme');

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildDetailsTestWidget(controller: controller, orgId: 'org-acme'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acme Corporation'), findsWidgets);
      expect(find.text('ORG-ACM-01'), findsWidgets);
      expect(find.text('Stores Active'), findsOneWidget);
      expect(find.text('Tenant Admins'), findsOneWidget);
      expect(find.text('ORGANIZATION PROFILE'), findsOneWidget);
      expect(find.text('GSTIN / Tax ID'), findsOneWidget);
      expect(find.text('US-EIN-12-3456789'), findsOneWidget);

      await tester.tap(find.text('Administrators'));
      await tester.pumpAndSettle();

      expect(find.text('David Warner'), findsOneWidget);
      expect(find.text('Elena Lindqvist'), findsOneWidget);
    });

    testWidgets('renders license details when License tab is selected', (
      tester,
    ) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );
      await controller.loadOrganizationDetails('org-acme');

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildDetailsTestWidget(controller: controller, orgId: 'org-acme'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('License'));
      await tester.pumpAndSettle();

      expect(find.text('PLAN ENTITLEMENTS'), findsOneWidget);
      expect(find.text('COMMERCIAL AGREEMENT'), findsOneWidget);
      expect(find.text('LICENSE HISTORY'), findsOneWidget);
    });

    testWidgets('shows the no-license state for an unlicensed organization', (
      tester,
    ) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );
      await controller.loadOrganizationDetails('org-crestline');

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildDetailsTestWidget(controller: controller, orgId: 'org-crestline'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('License'));
      await tester.pumpAndSettle();

      expect(find.text('No license assigned'), findsOneWidget);
      expect(find.text('Assign License'), findsOneWidget);
      expect(find.text('PLAN ENTITLEMENTS'), findsNothing);
      expect(find.text('Tier: Unassigned'), findsOneWidget);

      await tester.tap(find.text('Assign License'));
      await tester.pumpAndSettle();
      expect(
        find.text('Assign License is shown in this mock-only phase.'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when organization has no assigned admins', (
      tester,
    ) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );
      await controller.loadOrganizationDetails('org-crestline');

      await tester.pumpWidget(
        buildDetailsTestWidget(controller: controller, orgId: 'org-crestline'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Crestline Cold Storage'), findsWidgets);

      await tester.tap(find.text('Administrators'));
      await tester.pumpAndSettle();

      expect(find.text('No administrators assigned'), findsOneWidget);
      expect(
        find.textContaining('No active organization administrators'),
        findsOneWidget,
      );
    });

    testWidgets('opens Suspend dialog and confirms suspension', (tester) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );
      await controller.loadOrganizationDetails('org-acme');

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildDetailsTestWidget(controller: controller, orgId: 'org-acme'),
      );
      await tester.pumpAndSettle();

      // Find and tap Suspend button
      final suspendBtn = find.text('Suspend');
      expect(suspendBtn, findsOneWidget);
      await tester.tap(suspendBtn);
      await tester.pumpAndSettle();

      // Verify Suspend Confirmation Dialog
      expect(find.text('Suspend Organization?'), findsOneWidget);
      expect(
        find.textContaining(
          'will be marked as Suspended until it is reactivated.',
        ),
        findsOneWidget,
      );

      // Confirm suspend
      final confirmBtn = find.widgetWithText(
        ElevatedButton,
        'Suspend Organization',
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Check organization is now suspended
      final acme = await repository.getOrganizationById('org-acme');
      expect(acme?.isSuspended, isTrue);
    });

    testWidgets(
      'renders details screen header action row without BoxConstraints errors on desktop, tablet, and compact viewports',
      (tester) async {
        final repository = MockPlatformOrganizationsRepository();
        final controller = PlatformOrganizationsController(
          repository: repository,
        );
        await controller.loadOrganizationDetails('org-acme');

        const viewports = <String, Size>{
          'desktop': Size(1280, 900),
          'tablet': Size(768, 1024),
          'compact': Size(390, 844),
        };

        for (final entry in viewports.entries) {
          await tester.binding.setSurfaceSize(entry.value);

          FlutterErrorDetails? caughtDetails;
          final originalOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            caughtDetails = details;
            originalOnError?.call(details);
          };

          await tester.pumpWidget(
            buildDetailsTestWidget(
              controller: controller,
              orgId: 'org-acme',
              screenSize: entry.value,
            ),
          );
          await tester.pumpAndSettle();
          FlutterError.onError = originalOnError;

          final ex = tester.takeException();
          if (caughtDetails != null) {
            debugPrint('CAUGHT ON ${entry.key}: ${caughtDetails!.summary}');
            for (final line in caughtDetails!.toString().split('\n').take(25)) {
              debugPrint('  $line');
            }
          }
          expect(
            ex,
            isNull,
            reason:
                'Viewport ${entry.key} should not throw layout or BoxConstraints exceptions',
          );

          final editBtn = find.widgetWithText(
            OutlinedButton,
            'Edit Organization',
          );
          expect(
            editBtn,
            findsOneWidget,
            reason:
                'Edit Organization button must be present in viewport ${entry.key}',
          );

          final suspendBtn = find.widgetWithText(OutlinedButton, 'Suspend');
          expect(
            suspendBtn,
            findsOneWidget,
            reason: 'Suspend button must be present in viewport ${entry.key}',
          );

          final editRenderBox = tester.renderObject<RenderBox>(editBtn);
          expect(editRenderBox.hasSize, isTrue);
          expect(editRenderBox.size.width.isFinite, isTrue);
          expect(editRenderBox.size.height.isFinite, isTrue);
          expect(editRenderBox.size.width, greaterThan(0));

          final suspendRenderBox = tester.renderObject<RenderBox>(suspendBtn);
          expect(suspendRenderBox.hasSize, isTrue);
          expect(suspendRenderBox.size.width.isFinite, isTrue);
          expect(suspendRenderBox.size.height.isFinite, isTrue);
          expect(suspendRenderBox.size.width, greaterThan(0));
        }

        await tester.binding.setSurfaceSize(null);
      },
    );

    testWidgets(
      'renders reactivate button in header without BoxConstraints errors when org is suspended',
      (tester) async {
        final repository = MockPlatformOrganizationsRepository();
        final controller = PlatformOrganizationsController(
          repository: repository,
        );
        await controller.loadOrganizationDetails('org-crestline');

        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildDetailsTestWidget(
            controller: controller,
            orgId: 'org-crestline',
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Reactivate'), findsOneWidget);

        final headerReactivate = find
            .widgetWithText(OutlinedButton, 'Reactivate')
            .first;
        final renderBox = tester.renderObject<RenderBox>(headerReactivate);
        expect(renderBox.hasSize, isTrue);
        expect(renderBox.size.width.isFinite, isTrue);
        expect(renderBox.size.width, greaterThan(0));
      },
    );
  });

  group('AddOrganizationScreen Widget Tests', () {
    testWidgets('validates required fields before submitting', (tester) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );

      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlatformOrganizationsController>.value(
              value: controller,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AddOrganizationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Organization'), findsWidgets);
      expect(find.text('NEW TENANT'), findsOneWidget);

      // Tap Create Organization with empty fields
      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'Create Organization',
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Organization name is required to initialize workspace.'),
        findsOneWidget,
      );
      expect(find.text('Tax Identification (Optional)'), findsOneWidget);
      expect(find.text('Organization Code *'), findsNothing);
    });

    testWidgets(
      'stacks identity fields on phone and uses columns on wider layouts',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        const viewports = <String, Size>{
          'phone': Size(390, 844),
          'tablet': Size(768, 1024),
          'desktop': Size(1280, 1000),
        };

        for (final entry in viewports.entries) {
          await tester.binding.setSurfaceSize(entry.value);
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<PlatformOrganizationsController>(
                  create: (_) => PlatformOrganizationsController(
                    repository: MockPlatformOrganizationsRepository(),
                  ),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.light,
                home: const AddOrganizationScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: entry.key);
          final nameField = tester.getRect(find.byType(TextField).at(0));
          final taxIdField = tester.getRect(find.byType(TextField).at(1));
          if (entry.key == 'phone') {
            expect(taxIdField.left, closeTo(nameField.left, 1));
            expect(taxIdField.width, closeTo(nameField.width, 1));
          } else {
            expect(taxIdField.left, greaterThan(nameField.left));
          }
        }
      },
    );

    testWidgets(
      'successfully submits new organization and navigates to details',
      (tester) async {
        final repository = MockPlatformOrganizationsRepository();
        final controller = PlatformOrganizationsController(
          repository: repository,
        );
        await controller.loadOrganizations();

        final router = GoRouter(
          initialLocation: AppRoutes.platformOrganizationsAdd,
          routes: [
            GoRoute(
              path: AppRoutes.platformOrganizations,
              builder: (context, state) => const Scaffold(body: Text('List')),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddOrganizationScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => Scaffold(
                    body: Text('Details for ${state.pathParameters['id']}'),
                  ),
                ),
              ],
            ),
          ],
        );

        await tester.binding.setSurfaceSize(const Size(1280, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PlatformOrganizationsController>.value(
                value: controller,
              ),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter the user-supplied organization details, excluding its code.
        await tester.enterText(
          find.byType(TextField).at(0),
          'Starlight Express Logistics',
        );
        await tester.enterText(
          find.byType(TextField).at(1),
          'US-EIN-98-7654321',
        );
        await tester.pumpAndSettle();

        final submitBtn = find.widgetWithText(
          ElevatedButton,
          'Create Organization',
        );
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Verify org was registered in repository
        final createdOrg = controller.selectedOrganization;
        expect(createdOrg, isNotNull);
        expect(createdOrg?.name, 'Starlight Express Logistics');
        expect(createdOrg?.id, 'org-generated-001');
        expect(createdOrg?.code, 'ORG-001');
        expect(createdOrg?.taxIdentification, 'US-EIN-98-7654321');

        // Verify navigation to details screen
        expect(find.text('Details for org-generated-001'), findsOneWidget);
      },
    );
  });

  group('EditOrganizationScreen Widget Tests', () {
    testWidgets('renders pre-populated fields and discard changes modal', (
      tester,
    ) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );
      await controller.loadOrganizationDetails('org-acme');

      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlatformOrganizationsController>.value(
              value: controller,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const EditOrganizationScreen(organizationId: 'org-acme'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Organization'), findsWidgets);
      expect(find.text('Acme Corporation'), findsOneWidget);

      // Edit field to make dirty
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Acme Corporation International');
      await tester.pumpAndSettle();

      expect(find.text('Unsaved Changes'), findsOneWidget);

      // Tap Cancel
      final cancelBtn = find.widgetWithText(OutlinedButton, 'Cancel');
      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Discard Changes Dialog should appear
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard Changes'), findsOneWidget);
    });

    testWidgets(
      'loads and displays organization addressed by route ID even if selectedOrganization points to another org',
      (tester) async {
        final repository = MockPlatformOrganizationsRepository();
        final controller = PlatformOrganizationsController(
          repository: repository,
        );
        await controller.loadOrganizations();

        // Stale selection: controller.selectedOrganization points to Acme
        await controller.loadOrganizationDetails('org-acme');
        expect(controller.selectedOrganization?.id, 'org-acme');

        await tester.binding.setSurfaceSize(const Size(1280, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Open edit screen for Apex Logistics (org-apex), NOT Acme
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PlatformOrganizationsController>.value(
                value: controller,
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const EditOrganizationScreen(organizationId: 'org-apex'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must display Apex Logistics, NOT Acme Corporation!
        expect(find.text('Edit Organization'), findsWidgets);
        expect(find.text('Apex Logistics & Freight'), findsOneWidget);
        expect(find.text('# ORG-APX-01'), findsOneWidget);
        expect(find.text('Acme Corporation'), findsNothing);
      },
    );

    testWidgets(
      'submits updates to organization addressed by route ID without mutating stale selectedOrganization',
      (tester) async {
        final repository = MockPlatformOrganizationsRepository();
        final controller = PlatformOrganizationsController(
          repository: repository,
        );
        await controller.loadOrganizations();

        // Stale selection: controller.selectedOrganization points to Acme
        await controller.loadOrganizationDetails('org-acme');
        expect(controller.selectedOrganization?.id, 'org-acme');

        final router = GoRouter(
          initialLocation: AppRoutes.platformOrganizationEditPath('org-apex'),
          routes: [
            GoRoute(
              path: AppRoutes.platformOrganizations,
              builder: (context, state) => const Scaffold(body: Text('List')),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => Scaffold(
                    body: Text('Details for ${state.pathParameters['id']}'),
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => EditOrganizationScreen(
                        organizationId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        await tester.binding.setSurfaceSize(const Size(1280, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PlatformOrganizationsController>.value(
                value: controller,
              ),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Edit Apex's name
        final nameField = find.byType(TextField).first;
        await tester.enterText(nameField, 'Apex Logistics Global Hub');
        await tester.pumpAndSettle();

        // Tap Save Changes
        final saveBtn = find.widgetWithText(ElevatedButton, 'Save Changes');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Check repository: Apex must be updated, Acme must remain unchanged!
        final apex = await repository.getOrganizationById('org-apex');
        final acme = await repository.getOrganizationById('org-acme');

        expect(apex?.name, 'Apex Logistics Global Hub');
        expect(acme?.name, 'Acme Corporation'); // MUST NOT be overwritten!
      },
    );

    testWidgets(
      'loads organization asynchronously by route ID when not yet in memory and populates fields',
      (tester) async {
        final repository = MockPlatformOrganizationsRepository();
        final controller = PlatformOrganizationsController(
          repository: repository,
        );
        // Do not call loadOrganizations or loadOrganizationDetails ahead of time!

        await tester.binding.setSurfaceSize(const Size(1280, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PlatformOrganizationsController>.value(
                value: controller,
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const EditOrganizationScreen(
                organizationId: 'org-crestline',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Crestline Cold Storage'), findsOneWidget);
        expect(find.text('# ORG-CCS-77'), findsOneWidget);
      },
    );

    testWidgets('shows not found screen when organization ID does not exist', (
      tester,
    ) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );

      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlatformOrganizationsController>.value(
              value: controller,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const EditOrganizationScreen(organizationId: 'org-unknown'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Organization Not Found'), findsOneWidget);
      expect(find.text('Back to Organizations'), findsOneWidget);
    });

    testWidgets('validates required fields on edit submission', (tester) async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );
      await controller.loadOrganizationDetails('org-acme');

      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlatformOrganizationsController>.value(
              value: controller,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const EditOrganizationScreen(organizationId: 'org-acme'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, '   ');
      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(ElevatedButton, 'Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Organization name is required and cannot be empty.'),
        findsOneWidget,
      );
    });
  });
}
