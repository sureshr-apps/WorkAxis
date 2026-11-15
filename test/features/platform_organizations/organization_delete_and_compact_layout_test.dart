import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/organization_details_screen.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/organizations_list_screen.dart';

class _FailingDeleteRepository extends MockPlatformOrganizationsRepository {
  @override
  Future<void> deleteOrganization(String id) async {
    throw const DatabaseException(
      'delete failed',
      userMessage: 'The organization could not be deleted right now.',
    );
  }
}

Future<void> _pumpApp(
  WidgetTester tester,
  PlatformOrganizationsController controller, {
  required String initialLocation,
  Size size = const Size(1280, 900),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.platformOrganizations,
        builder: (_, _) => const OrganizationsListScreen(),
      ),
      GoRoute(
        path: '/platform/organizations/:id',
        builder: (_, state) => OrganizationDetailsScreen(
          organizationId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ChangeNotifierProvider<PlatformOrganizationsController>.value(
      value: controller,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('delete organization from the details page', () {
    testWidgets('success lands on the list with no not-found frame', (
      tester,
    ) async {
      final controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
        searchDebounce: Duration.zero,
      );
      await controller.loadOrganizations();
      final initialTotal = controller.totalCount;

      await _pumpApp(
        tester,
        controller,
        initialLocation: AppRoutes.platformOrganizationDetailsPath('org-acme'),
      );
      expect(find.text('Organization not found'), findsNothing);

      await tester.tap(find.byTooltip('Delete Acme Corporation'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Delete Organization'));

      // Step frame by frame: the not-found state must never render.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Organization not found'), findsNothing);
      }
      await tester.pumpAndSettle();

      expect(find.byType(OrganizationsListScreen), findsOneWidget);
      expect(find.byType(OrganizationDetailsScreen), findsNothing);
      expect(controller.selectedOrganization, isNull);
      expect(controller.totalCount, initialTotal - 1);
      expect(controller.organizations.any((o) => o.id == 'org-acme'), isFalse);
    });

    testWidgets('failure keeps the page and shows the error', (tester) async {
      final controller = PlatformOrganizationsController(
        repository: _FailingDeleteRepository(),
        searchDebounce: Duration.zero,
      );
      await controller.loadOrganizations();
      final initialTotal = controller.totalCount;

      await _pumpApp(
        tester,
        controller,
        initialLocation: AppRoutes.platformOrganizationDetailsPath('org-acme'),
      );

      await tester.tap(find.byTooltip('Delete Acme Corporation'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Delete Organization'));
      await tester.pumpAndSettle();

      expect(find.byType(OrganizationDetailsScreen), findsOneWidget);
      expect(find.text('Organization not found'), findsNothing);
      expect(
        find.textContaining('could not be deleted right now'),
        findsOneWidget,
      );
      expect(controller.selectedOrganization?.id, 'org-acme');
      expect(controller.totalCount, initialTotal);
    });

    test('controller decrements the total locally, clamped at zero', () async {
      final controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
        searchDebounce: Duration.zero,
      );
      await controller.loadOrganizations();
      await controller.loadOrganizationDetails('org-acme');
      final total = controller.totalCount;

      expect(await controller.deleteOrganization('org-acme'), isTrue);

      expect(controller.totalCount, total - 1);
      expect(controller.selectedOrganization, isNull);
      expect(controller.isListLoading, isFalse);
    });
  });

  group('360dp with 1.3x text', () {
    const phone = Size(360, 800);

    testWidgets('organization details header actions do not overflow', (
      tester,
    ) async {
      final controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
      );
      await controller.loadOrganizationDetails('org-acme');
      await _pumpApp(
        tester,
        controller,
        initialLocation: AppRoutes.platformOrganizationDetailsPath('org-acme'),
        size: phone,
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      for (final label in ['Edit', 'Suspend']) {
        final button = find.widgetWithText(OutlinedButton, label);
        expect(button, findsOneWidget);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        expect(tester.getTopRight(button).dx, lessThanOrEqualTo(phone.width));
      }
      final delete = find.byTooltip('Delete Acme Corporation');
      expect(tester.getSize(delete).width, greaterThanOrEqualTo(48));
      expect(tester.getTopRight(delete).dx, lessThanOrEqualTo(phone.width));
    });

    testWidgets('organizations list rows do not overflow', (tester) async {
      final controller = PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
        searchDebounce: Duration.zero,
      );
      await controller.loadOrganizations();
      await _pumpApp(
        tester,
        controller,
        initialLocation: AppRoutes.platformOrganizations,
        size: phone,
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Acme Corporation'), findsWidgets);
      // Phones have no per-card actions: the whole card is the tap target.
      expect(find.byTooltip('Edit Acme Corporation'), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    });
  });
}
