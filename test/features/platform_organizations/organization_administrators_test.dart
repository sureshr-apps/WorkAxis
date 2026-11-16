import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_draft.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_admin_rules.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/organization_admin_form_route.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/organization_details_screen.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_admin_form_page.dart';

/// Fails every administrator write, to test error surfacing.
class _FailingAdminRepository extends MockPlatformOrganizationsRepository {
  @override
  Future<void> resetOrganizationAdminPassword({
    required String organizationId,
    required String adminId,
    required String newPassword,
  }) => throw const NetworkException('offline');
}

Widget _formHost(OrganizationAdminSubmit onSubmit) => MaterialApp(
  theme: AppTheme.light,
  home: OrganizationAdminFormPage(
    backLabel: 'Acme Corporation',
    onSubmit: onSubmit,
    onClose: () {},
    onSaved: () {},
  ),
);

Widget _detailsHost(PlatformOrganizationsController controller, String id) =>
    ChangeNotifierProvider<PlatformOrganizationsController>.value(
      value: controller,
      child: MaterialApp(
        theme: AppTheme.light,
        home: OrganizationDetailsScreen(organizationId: id),
      ),
    );

void main() {
  group('administrator management in the controller', () {
    late PlatformOrganizationsController controller;

    setUp(() async {
      controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
      );
      await controller.loadOrganizationDetails('org-acme');
    });

    tearDown(() => controller.dispose());

    test('adding an administrator updates the selected organization', () async {
      final before = controller.selectedOrganization!.admins.length;
      final ok = await controller.createAdministrator(
        'org-acme',
        const OrganizationAdminDraft(
          name: 'Nina Rao',
          username: 'nina.rao',
          initialPassword: 'password1',
        ),
      );
      expect(ok, isTrue);
      expect(controller.actionErrorMessage, isNull);
      final admins = controller.selectedOrganization!.admins;
      expect(admins.length, before + 1);
      expect(admins.last.id, startsWith('admin-mock-'));
    });

    test('an invalid draft fails with a message and changes nothing', () async {
      final before = controller.selectedOrganization!.admins.length;
      final ok = await controller.createAdministrator(
        'org-acme',
        const OrganizationAdminDraft(name: '', username: 'x'),
      );
      expect(ok, isFalse);
      expect(controller.actionErrorMessage, isNotEmpty);
      expect(controller.selectedOrganization!.admins.length, before);
    });

    test('the last active administrator cannot be suspended', () async {
      await controller.loadOrganizationDetails('org-apex');
      final only = controller.selectedOrganization!.admins.single;
      expect(controller.isLastActiveAdministrator(only.id), isTrue);

      final ok = await controller.setAdministratorStatus(
        'org-apex',
        only.id,
        OrganizationAdminStatus.suspended,
      );

      expect(ok, isFalse);
      expect(
        controller.actionErrorMessage,
        OrganizationAdminRules.lastActiveAdminMessage,
      );
      expect(
        controller.selectedOrganization!.admins.single.status,
        OrganizationAdminStatus.active,
      );
    });

    test(
      'with two active admins one may be suspended, then not the other',
      () async {
        final admins = controller.selectedOrganization!.admins;
        expect(
          await controller.setAdministratorStatus(
            'org-acme',
            admins.first.id,
            OrganizationAdminStatus.suspended,
          ),
          isTrue,
        );
        expect(controller.isLastActiveAdministrator(admins.last.id), isTrue);
        expect(
          await controller.setAdministratorStatus(
            'org-acme',
            admins.last.id,
            OrganizationAdminStatus.suspended,
          ),
          isFalse,
        );
      },
    );

    test('a failed password reset surfaces a safe message', () async {
      final failing = PlatformOrganizationsController(
        repository: _FailingAdminRepository(),
      );
      addTearDown(failing.dispose);
      await failing.loadOrganizationDetails('org-acme');
      final adminId = failing.selectedOrganization!.admins.first.id;

      final ok = await failing.resetAdministratorPassword(
        'org-acme',
        adminId,
        'password1',
      );

      expect(ok, isFalse);
      expect(failing.actionErrorMessage, isNotNull);
      failing.clearActionError();
      expect(failing.actionErrorMessage, isNull);
    });
  });

  group('OrganizationAdminFormPage', () {
    testWidgets('shows a message under each invalid field', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var submitted = false;
      await tester.pumpWidget(
        _formHost((draft) async {
          submitted = true;
          return null;
        }),
      );

      await tester.tap(find.widgetWithText(AppButton, 'Add Administrator'));
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('Enter the full name.'), findsOneWidget);
      expect(find.textContaining('Username must be'), findsOneWidget);
      expect(find.textContaining('Password must be'), findsOneWidget);
      // Email and phone are optional, so blank values raise no error.
      expect(find.text('Enter a valid email address.'), findsNothing);
    });

    testWidgets('validates optional email and phone only when provided', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_formHost((_) async => null));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'johndoe');
      await tester.enterText(fields.at(2), 'not-an-email');
      await tester.enterText(fields.at(3), '123');
      await tester.enterText(fields.at(4), 'password1');

      await tester.tap(find.widgetWithText(AppButton, 'Add Administrator'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.textContaining('country code'), findsOneWidget);
    });

    testWidgets('submits a valid draft with only the required fields', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      OrganizationAdminDraft? received;
      await tester.pumpWidget(
        _formHost((draft) async {
          received = draft;
          return null;
        }),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'johndoe');
      await tester.enterText(fields.at(4), 'password1');

      await tester.tap(find.widgetWithText(AppButton, 'Add Administrator'));
      await tester.pumpAndSettle();

      expect(received, isNotNull);
      expect(received!.name, 'John Doe');
      expect(received!.username, 'johndoe');
      expect(received!.email, isEmpty);
      expect(received!.initialPassword, 'password1');
    });

    testWidgets('a failed save keeps the page open with the entries', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _formHost((_) async => 'That username is already in use.'),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'johndoe');
      await tester.enterText(fields.at(4), 'password1');

      await tester.tap(find.widgetWithText(AppButton, 'Add Administrator'));
      await tester.pumpAndSettle();

      expect(find.text('That username is already in use.'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });
  });

  group('OrganizationDetailsScreen administrators tab', () {
    testWidgets(
      'suspending the only active admin explains the refusal on tap',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = PlatformOrganizationsController(
          repository: MockPlatformOrganizationsRepository(),
        );
        addTearDown(controller.dispose);
        await controller.loadOrganizationDetails('org-apex');

        await tester.pumpWidget(_detailsHost(controller, 'org-apex'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Administrators'));
        await tester.pumpAndSettle();

        expect(
          find.byTooltip('The only active administrator cannot be suspended'),
          findsOneWidget,
        );
        expect(find.byTooltip('Suspend administrator'), findsNothing);

        await tester.tap(
          find.byTooltip('The only active administrator cannot be suspended'),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(OrganizationAdminRules.lastActiveAdminMessage),
          findsOneWidget,
        );
        // No confirmation is offered, and the administrator stays active.
        expect(find.text('Restore'), findsNothing);
      },
    );

    testWidgets('deleting the only active administrator explains the refusal', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
      );
      addTearDown(controller.dispose);
      await controller.loadOrganizationDetails('org-apex');

      await tester.pumpWidget(_detailsHost(controller, 'org-apex'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrators'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete administrator').first);
      await tester.pumpAndSettle();

      expect(
        find.text(OrganizationAdminRules.lastActiveAdminMessage),
        findsOneWidget,
      );
      expect(find.text('Delete administrator?'), findsNothing);
    });

    testWidgets('deleting an administrator asks first, then removes the row', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = MockPlatformOrganizationsRepository();
      final org = (await repository.getOrganizationsPage()).items.firstWhere(
        (o) => o.admins.length >= 2,
      );
      final controller = PlatformOrganizationsController(
        repository: repository,
      );
      addTearDown(controller.dispose);
      await controller.loadOrganizationDetails(org.id);
      final victimIndex = controller.selectedOrganization!.admins.indexWhere(
        (a) => !controller.isLastActiveAdministrator(a.id),
      );
      final victim = controller.selectedOrganization!.admins[victimIndex];

      await tester.pumpWidget(_detailsHost(controller, org.id));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrators'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete administrator').at(victimIndex));
      await tester.pumpAndSettle();
      expect(find.text('Delete administrator?'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Delete administrator'),
      );
      await tester.pumpAndSettle();

      expect(find.text('${victim.name} deleted.'), findsOneWidget);
      expect(
        controller.selectedOrganization!.admins.any((a) => a.id == victim.id),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('suspend then restore reflects the account state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
      );
      addTearDown(controller.dispose);
      await controller.loadOrganizationDetails('org-acme');

      await tester.pumpWidget(_detailsHost(controller, 'org-acme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrators'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Suspend administrator').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.widgetWithText(AppButton, 'Suspend'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Restore administrator'), findsOneWidget);
      expect(find.text('SUSPENDED'), findsOneWidget);
    });

    testWidgets('does not show a previously selected organization', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
      );
      addTearDown(controller.dispose);
      await controller.loadOrganizationDetails('org-acme');

      await tester.pumpWidget(_detailsHost(controller, 'org-apex'));

      // First frame: loader, not Acme's record.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Acme Corporation'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Apex Logistics & Freight'), findsWidgets);
    });

    for (final size in const [
      Size(390, 800),
      Size(768, 1024),
      Size(1280, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width.toInt()}dp', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = PlatformOrganizationsController(
          repository: MockPlatformOrganizationsRepository(),
        );
        addTearDown(controller.dispose);
        await controller.loadOrganizationDetails('org-acme');

        await tester.pumpWidget(_detailsHost(controller, 'org-acme'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Administrators'));
        await tester.pumpAndSettle();

        expect(find.text('David Warner'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('administrator pages in the router', () {
    testWidgets(
      'add opens a page whose breadcrumb returns to the organization',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = PlatformOrganizationsController(
          repository: MockPlatformOrganizationsRepository(),
        );
        addTearDown(controller.dispose);
        final router = GoRouter(
          initialLocation: AppRoutes.platformOrganizationAdminAddPath(
            'org-acme',
          ),
          routes: [
            GoRoute(
              path: AppRoutes.platformOrganizationDetails,
              builder: (context, state) => OrganizationDetailsScreen(
                organizationId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: '/platform/organizations/:id/administrators/add',
              builder: (context, state) => OrganizationAdminFormRoute(
                organizationId: state.pathParameters['id'] ?? '',
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ChangeNotifierProvider<PlatformOrganizationsController>.value(
            value: controller,
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OrganizationAdminFormPage), findsOneWidget);
        expect(find.text('Add Administrator'), findsWidgets);

        await tester.tap(
          find.descendant(
            of: find.byType(PageBreadcrumb),
            matching: find.byType(InkWell),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OrganizationAdminFormPage), findsNothing);
        expect(find.byType(OrganizationDetailsScreen), findsOneWidget);
      },
    );
  });
}
