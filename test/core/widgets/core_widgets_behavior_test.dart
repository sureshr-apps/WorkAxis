import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/responsive/content_width_scope.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';

Widget _host(Widget child, {double textScale = 1.0, Size? size}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(
        size: size ?? const Size(800, 900),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

List<Widget> _cards(int count) => [
  for (var i = 0; i < count; i++)
    AppKpiCard(title: 'Metric $i', value: '${i * 111}', icon: Icons.bolt),
];

void main() {
  group('AppButton loading state', () {
    for (final variant in AppButtonVariant.values) {
      testWidgets('shows a visible spinner on ${variant.name}', (tester) async {
        await tester.pumpWidget(
          _host(
            AppButton(
              text: 'Save',
              variant: variant,
              isLoading: true,
              onPressed: () {},
            ),
          ),
        );

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        final color =
            (indicator.valueColor! as AlwaysStoppedAnimation<Color>).value;
        expect(color, switch (variant) {
          AppButtonVariant.primary => AppColors.onPrimary,
          AppButtonVariant.secondaryTonal => AppColors.onPrimaryContainer,
          AppButtonVariant.outlined => AppColors.primary,
          AppButtonVariant.destructive => AppColors.onPrimary,
        });
      });
    }

    testWidgets('loading primary button keeps its filled colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton.primary(text: 'Sign In', isLoading: true, onPressed: () {}),
        ),
      );

      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      expect(
        style.backgroundColor!.resolve({WidgetState.disabled}),
        AppColors.primary,
      );
      expect(
        style.foregroundColor!.resolve({WidgetState.disabled}),
        AppColors.onPrimary,
      );
    });

    testWidgets('does not invoke onPressed while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          AppButton.primary(
            text: 'Go',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(taps, 0);
    });
  });

  group('AppKpiCard', () {
    testWidgets('grows instead of overflowing at 2x text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 220,
            child: AppKpiCard(
              title: 'Total Organizations',
              value: '12',
              icon: Icons.business,
              footerText: 'Across the platform',
            ),
          ),
          textScale: 2.0,
        ),
      );

      expect(tester.takeException(), isNull);
      final height = tester.getSize(find.byType(AppKpiCard)).height;
      expect(height, greaterThanOrEqualTo(AppKpiCard.minHeight));
    });

    testWidgets('scales a very long value down instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 120,
            child: AppKpiCard(title: 'Revenue', value: '1,234,567,890'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FittedBox), findsWidgets);
    });
  });

  group('ResponsiveKpiSection', () {
    testWidgets('uses the content width, not the screen width', (tester) async {
      // 1200dp screen, but only 560dp available to the content.
      await tester.pumpWidget(
        _host(
          ContentWidthScope(
            width: 560,
            child: ResponsiveKpiSection(cards: _cards(4)),
          ),
          size: const Size(1200, 900),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('lays four cards out in one row at expanded content width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ContentWidthScope(
            width: 1000,
            child: ResponsiveKpiSection(cards: _cards(4)),
          ),
          size: const Size(1400, 900),
        ),
      );

      expect(find.byType(PageView), findsNothing);
      final tops = {
        for (var i = 0; i < 4; i++)
          tester.getTopLeft(find.text('Metric $i')).dy,
      };
      expect(tops, hasLength(1));
    });

    testWidgets('medium content width uses two columns', (tester) async {
      await tester.pumpWidget(
        _host(
          ContentWidthScope(
            width: 700,
            child: ResponsiveKpiSection(cards: _cards(4)),
          ),
        ),
      );

      final tops = {
        for (var i = 0; i < 4; i++)
          tester.getTopLeft(find.text('Metric $i')).dy,
      };
      expect(tops, hasLength(2));
    });
  });

  group('AppTextField.search', () {
    testWidgets('clear button appears while typing and clears the field', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];

      await tester.pumpWidget(
        _host(
          AppTextField.search(controller: controller, onChanged: changes.add),
        ),
      );

      expect(find.byTooltip('Clear'), findsNothing);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(find.byTooltip('Clear'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changes.last, isEmpty);
      expect(find.byTooltip('Clear'), findsNothing);
    });

    testWidgets('label is exposed through field semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const AppTextField(label: 'Employee name')),
      );

      expect(find.bySemanticsLabel('Employee name'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AppPasswordField', () {
    testWidgets('visibility toggle has a tooltip that follows its state', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AppPasswordField()));

      expect(find.byTooltip('Show password'), findsOneWidget);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });
  });

  group('ErrorBanner', () {
    testWidgets('dismiss and retry meet the 48dp target and are announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          ErrorBanner(
            message: 'Network down',
            onDismiss: () {},
            onRetry: () {},
          ),
        ),
      );

      final dismiss = tester.getSize(find.byTooltip('Dismiss'));
      expect(dismiss.width, greaterThanOrEqualTo(48));
      expect(dismiss.height, greaterThanOrEqualTo(48));
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Retry')).height,
        greaterThanOrEqualTo(48),
      );
      expect(find.bySemanticsLabel('Error: Network down'), findsOneWidget);
      handle.dispose();
    });
  });
}
