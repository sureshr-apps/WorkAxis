import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/plans/data/mock_license_plans_repository.dart';
import 'package:workaxis/features/plans/domain/license_plan_policy.dart';
import 'package:workaxis/features/plans/presentation/controllers/license_plans_controller.dart';
import 'package:workaxis/features/plans/presentation/screens/license_plan_form_screen.dart';

Future<LicensePlansController> _pump(
  WidgetTester tester, {
  String? planId,
}) async {
  final controller = LicensePlansController(
    repository: MockLicensePlansRepository(),
    searchDebounce: Duration.zero,
  );
  addTearDown(controller.dispose);
  await controller.loadPlans();

  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => LicensePlanFormScreen(planId: planId),
      ),
      GoRoute(
        path: '/platform/plans',
        builder: (_, _) => const Scaffold(body: Text('Plans list')),
      ),
    ],
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<LicensePlansController>.value(
      value: controller,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

/// The text field whose label is [label].
Finder _fieldLabelled(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(AppTextField));

/// The editable text inside the field labelled [label].
Finder _inputLabelled(String label) => find.descendant(
  of: _fieldLabelled(label),
  matching: find.byType(TextField),
);

String _textOf(WidgetTester tester, Finder field) {
  final input = find.descendant(of: field, matching: find.byType(TextField));
  return tester.widget<TextField>(input).controller!.text;
}

void main() {
  testWidgets(
    'a blank name and a zero store limit show errors on those fields only',
    (tester) async {
      await _pump(tester);

      await tester.enterText(_inputLabelled('Maximum Stores *'), '0');
      await tester.ensureVisible(find.text('Create Plan'));
      await tester.tap(find.text('Create Plan'));
      await tester.pumpAndSettle();

      final nameField = _fieldLabelled('Plan Name *');
      final storesField = _fieldLabelled('Maximum Stores *');
      final usersField = _fieldLabelled('Maximum Users *');

      expect(
        find.descendant(
          of: nameField,
          matching: find.text('Plan Name is required.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: storesField,
          matching: find.text(LicensePlanPolicy.maxStoresMessage),
        ),
        findsOneWidget,
      );
      expect(find.text(LicensePlanPolicy.maxUsersMessage), findsNothing);
      expect(
        find.descendant(
          of: usersField,
          matching: find.text(LicensePlanPolicy.maxUsersMessage),
        ),
        findsNothing,
      );
      // The entered value is kept so the user can correct it.
      expect(_textOf(tester, storesField), '0');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('editing a field clears its own error', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(find.text('Create Plan'));
    await tester.tap(find.text('Create Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Plan Name is required.'), findsOneWidget);

    await tester.enterText(_inputLabelled('Plan Name *'), 'Starter');
    await tester.pumpAndSettle();

    expect(find.text('Plan Name is required.'), findsNothing);
  });

  testWidgets(
    'edit seeds the fields from the plan and returns to the list on save',
    (tester) async {
      final controller = await _pump(tester, planId: 'plan-plus');

      final nameField = _fieldLabelled('Plan Name *');
      expect(_textOf(tester, nameField), 'Plus');

      final usersField = _fieldLabelled('Maximum Users *');
      expect(_textOf(tester, usersField), '25');
      await tester.enterText(_inputLabelled('Maximum Users *'), '30');

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Plans list'), findsOneWidget);
      expect(controller.findPlan('plan-plus')!.maxUsers, 30);
      expect(find.text('Plan "Plus" updated successfully.'), findsOneWidget);
    },
  );

  testWidgets('a server refusal stays on the form and is shown as a banner', (
    tester,
  ) async {
    final controller = await _pump(tester, planId: 'plan-pro');
    await controller.loadPlans();

    final levelDown = find.byTooltip('Decrease plan level');
    // Pro is level 3; moving it to level 1 collides with Basic.
    await tester.ensureVisible(levelDown);
    await tester.tap(levelDown);
    await tester.pump();
    await tester.tap(levelDown);
    await tester.pump();
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Plans list'), findsNothing);
    expect(find.text('A plan with this level already exists.'), findsOneWidget);
  });
}
