import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';

void main() {
  group('Canonical Template Tests', () {
    testWidgets('AppKpiCard renders metric, inline badge, and ratio total', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppKpiCard(
              title: 'Total Active Employees',
              value: '142',
              total: '/ 150',
              inlineBadge: Text('+12% this month'),
              icon: Icons.people_outline,
              footerText: 'All branches reporting on time',
            ),
          ),
        ),
      );

      expect(find.text('Total Active Employees'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      expect(find.text('/ 150'), findsOneWidget);
      expect(find.text('+12% this month'), findsOneWidget);
      expect(find.text('All branches reporting on time'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets(
      'ResponsiveKpiSection renders cards in PageView on compact screens',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveKpiSection(
                cards: const [
                  AppKpiCard(title: 'KPI 1', value: '10'),
                  AppKpiCard(title: 'KPI 2', value: '20'),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PageView), findsOneWidget);
        expect(find.text('KPI 1'), findsOneWidget);
      },
    );

    testWidgets('ResponsiveKpiSection renders all cards on desktop screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveKpiSection(
              cards: const [
                AppKpiCard(title: 'KPI 1', value: '10'),
                AppKpiCard(title: 'KPI 2', value: '20'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsNothing);
      expect(find.text('KPI 1'), findsOneWidget);
      expect(find.text('KPI 2'), findsOneWidget);
    });

    testWidgets('AppButton variants and loading state', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppButton.primary(
                  text: 'Primary Action',
                  onPressed: () => pressed = true,
                ),
                AppButton.secondary(text: 'Secondary Action', onPressed: () {}),
                AppButton.outlined(text: 'Outlined Action', onPressed: () {}),
                AppButton.primary(
                  text: 'Loading Action',
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.text('Secondary Action'), findsOneWidget);
      expect(find.text('Outlined Action'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Primary Action'));
      expect(pressed, isTrue);
    });

    testWidgets('AppPasswordField toggles password visibility on icon tap', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'secret123');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppPasswordField(controller: controller)),
        ),
      );

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      TextField textField = tester.widget(textFieldFinder);
      expect(textField.obscureText, isTrue);

      // Tap toggle visibility icon
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      textField = tester.widget(textFieldFinder);
      expect(textField.obscureText, isFalse);
    });

    testWidgets('AppPageHeader renders title, eyebrow, subtitle, and action', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPageHeader(
              eyebrow: 'Operations Overview',
              title: 'Dashboard Metrics',
              subtitle: 'Multi-branch performance summary',
              action: AppButton.primary(text: 'New Report', onPressed: () {}),
            ),
          ),
        ),
      );

      expect(find.text('OPERATIONS OVERVIEW'), findsOneWidget);
      expect(find.text('Dashboard Metrics'), findsOneWidget);
      expect(find.text('Multi-branch performance summary'), findsOneWidget);
      expect(find.text('New Report'), findsOneWidget);
    });
  });
}
