import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/edit_organization_screen.dart';

class _FailingUpdateRepository extends MockPlatformOrganizationsRepository {
  @override
  Future<CustomerOrganization> updateOrganization(
    CustomerOrganization organization,
  ) => Future.error(StateError('boom'));
}

Future<(GoRouter, PlatformOrganizationsController)> _pumpEdit(
  WidgetTester tester, {
  MockPlatformOrganizationsRepository? repository,
  Size size = const Size(1280, 1000),
}) async {
  final controller = PlatformOrganizationsController(
    repository: repository ?? MockPlatformOrganizationsRepository(),
  );
  await controller.loadOrganizationDetails('org-acme');
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home page')),
      ),
      GoRoute(
        path: '/edit/:id',
        builder: (_, state) =>
            EditOrganizationScreen(organizationId: state.pathParameters['id']!),
      ),
    ],
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider<PlatformOrganizationsController>.value(
      value: controller,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  router.push('/edit/org-acme');
  await tester.pumpAndSettle();
  return (router, controller);
}

void main() {
  testWidgets('tax identification is prefilled and saved', (tester) async {
    final (_, controller) = await _pumpEdit(tester);

    expect(find.text('US-EIN-12-3456789'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'US-EIN-12-3456789'),
      'GSTIN-99',
    );
    final save = find.widgetWithText(AppButton, 'Save Changes');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(controller.selectedOrganization?.taxIdentification, 'GSTIN-99');
    expect(find.text('Home page'), findsOneWidget);
  });

  testWidgets('system back with unsaved changes asks before discarding', (
    tester,
  ) async {
    await _pumpEdit(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Acme Corporation'),
      'Acme Renamed',
    );
    await tester.pump();
    expect(find.text('Unsaved Changes'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Organization'), findsWidgets);
    expect(find.text('Home page'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Home page'), findsOneWidget);
  });

  testWidgets('back without edits leaves immediately', (tester) async {
    await _pumpEdit(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Home page'), findsOneWidget);
  });

  testWidgets('invalid optional email and phone show per-field errors', (
    tester,
  ) async {
    await _pumpEdit(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'operations@acmecorp.com'),
      'not-an-email',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '+1 (555) 234-8900'),
      '12',
    );
    final save = find.widgetWithText(AppButton, 'Save Changes');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.textContaining('with country code'), findsOneWidget);
  });

  testWidgets('server failure shows the controller message, not a validation '
      'title', (tester) async {
    await _pumpEdit(tester, repository: _FailingUpdateRepository());

    await tester.enterText(
      find.widgetWithText(TextField, 'Acme Corporation'),
      'Acme Renamed',
    );
    final save = find.widgetWithText(AppButton, 'Save Changes');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Update Failed'), findsOneWidget);
    expect(find.textContaining('Form Validation'), findsNothing);
    expect(
      find.text('The organization could not be updated. Please try again.'),
      findsOneWidget,
    );
  });

  for (final entry in const {
    'desktop': Size(1280, 900),
    'tablet': Size(768, 1024),
    'compact': Size(390, 844),
  }.entries) {
    testWidgets('edit form lays out without overflow on ${entry.key}', (
      tester,
    ) async {
      await _pumpEdit(tester, size: entry.value);
      expect(tester.takeException(), isNull);
    });
  }
}
