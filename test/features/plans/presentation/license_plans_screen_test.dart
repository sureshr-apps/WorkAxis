import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/features/plans/data/mock_license_plans_data_source.dart';
import 'package:workaxis/features/plans/data/mock_license_plans_repository.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/presentation/controllers/license_plans_controller.dart';
import 'package:workaxis/features/plans/presentation/screens/license_plans_screen.dart';
import 'package:workaxis/features/plans/presentation/widgets/license_plan_card.dart';
import 'package:workaxis/features/plans/presentation/widgets/license_plan_confirm_dialog.dart';

Future<LicensePlansController> _pump(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
}) async {
  final controller = LicensePlansController(
    repository: MockLicensePlansRepository(),
    searchDebounce: Duration.zero,
  );
  addTearDown(controller.dispose);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const LicensePlansScreen()),
      GoRoute(
        path: '/platform/plans/add',
        builder: (_, _) => const Scaffold(body: Text('Add route')),
      ),
      GoRoute(
        path: '/platform/plans/:id/edit',
        builder: (_, state) =>
            Scaffold(body: Text('Edit ${state.pathParameters['id']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<LicensePlansController>.value(
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
  return controller;
}

void main() {
  group('plan list layout', () {
    for (final width in [390.0, 360.0]) {
      testWidgets(
        'shows the five seeded plan cards at ${width.toInt()}dp with 1.3x text and no overflow',
        (tester) async {
          await _pump(tester, size: Size(width, 3000), textScale: 1.3);

          expect(tester.takeException(), isNull);
          expect(find.byType(LicensePlanCard), findsNWidgets(5));
          expect(find.byType(AppKpiCard), findsWidgets);
          expect(find.text('All Statuses'), findsOneWidget);
          expect(find.text('Auto-sorted by Level'), findsOneWidget);
        },
      );
    }

    testWidgets('a plan card shows its limits and plan code', (tester) async {
      await _pump(tester, size: const Size(390, 3000));

      expect(find.text('Plus'), findsOneWidget);
      expect(find.text('Level 2'), findsWidgets);
      expect(find.text('5 Stores'), findsOneWidget);
      expect(find.text('25 Users'), findsOneWidget);
      expect(find.text('ID: PLN-0000000000A2-PLUS'), findsOneWidget);
    });

    testWidgets('wide layouts place the first three plans in one row', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1280, 900));

      final basicTop = tester.getTopLeft(
        find.byKey(const Key('license-plan-card-plan-basic')),
      );
      final plusTop = tester.getTopLeft(
        find.byKey(const Key('license-plan-card-plan-plus')),
      );
      final proTop = tester.getTopLeft(
        find.byKey(const Key('license-plan-card-plan-pro')),
      );
      expect(plusTop.dy, basicTop.dy);
      expect(proTop.dy, basicTop.dy);
      expect(tester.takeException(), isNull);
    });
  });

  group('plan actions', () {
    testWidgets('deactivate asks first and then changes the status', (
      tester,
    ) async {
      final controller = await _pump(tester, size: const Size(390, 3000));

      await tester.tap(find.byTooltip('Deactivate Pro'));
      await tester.pumpAndSettle();

      expect(find.text('Deactivate Pro?'), findsOneWidget);
      expect(controller.findPlan('plan-pro')!.isActive, isTrue);

      await tester.tap(find.text('Deactivate Plan'));
      await tester.pumpAndSettle();

      expect(controller.findPlan('plan-pro')!.status, PlanStatus.inactive);
      expect(find.text('Plan "Pro" deactivated.'), findsOneWidget);
    });

    testWidgets('delete shows the server refusal inside the dialog', (
      tester,
    ) async {
      final controller = await _pump(tester, size: const Size(390, 3000));

      await tester.tap(find.byTooltip('Delete Basic'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Basic?'), findsOneWidget);

      await tester.tap(find.text('Delete Plan'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(LicensePlanConfirmDialog),
          matching: find.text(planReferencedMessage),
        ),
        findsOneWidget,
      );
      expect(controller.findPlan('plan-basic'), isNotNull);
    });

    testWidgets('Add Plan opens the add route', (tester) async {
      await _pump(tester, size: const Size(390, 900));

      await tester.tap(find.text('Add Plan').first);
      await tester.pumpAndSettle();

      expect(find.text('Add route'), findsOneWidget);
    });
  });
}
