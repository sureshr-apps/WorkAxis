import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_theme.dart';

void main() {
  group('AppTheme Global Button Theme Constraints Regression Tests', () {
    test(
      'ElevatedButton and OutlinedButton themes specify finite minimum width',
      () {
        final theme = AppTheme.light;

        final elevatedMinSize = theme.elevatedButtonTheme.style?.minimumSize
            ?.resolve({});
        expect(elevatedMinSize, isNotNull);
        expect(
          elevatedMinSize!.width.isFinite,
          isTrue,
          reason: 'ElevatedButton minimum width must be finite to avoid infinite width layout crashes',
        );
        expect(elevatedMinSize.width, equals(AppSpacing.minButtonWidth));
        expect(
          elevatedMinSize.height,
          greaterThanOrEqualTo(AppSpacing.minTouchTarget),
        );

        final outlinedMinSize = theme.outlinedButtonTheme.style?.minimumSize
            ?.resolve({});
        expect(outlinedMinSize, isNotNull);
        expect(
          outlinedMinSize!.width.isFinite,
          isTrue,
          reason: 'OutlinedButton minimum width must be finite to avoid infinite width layout crashes',
        );
        expect(outlinedMinSize.width, equals(AppSpacing.minButtonWidth));
        expect(
          outlinedMinSize.height,
          greaterThanOrEqualTo(AppSpacing.minTouchTarget),
        );
      },
    );

    testWidgets(
      'OutlinedButton and ElevatedButton build inside unconstrained Row without layout exceptions',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Organization'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Reactivate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Edit Organization'), findsOneWidget);
        expect(find.text('Reactivate'), findsOneWidget);

        final outlinedRenderBox = tester.renderObject<RenderBox>(
          find.text('Edit Organization'),
        );
        expect(outlinedRenderBox.hasSize, isTrue);
        expect(outlinedRenderBox.size.width.isFinite, isTrue);
        expect(outlinedRenderBox.size.height.isFinite, isTrue);
      },
    );
  });
}
