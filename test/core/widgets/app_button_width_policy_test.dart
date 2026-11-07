import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/widgets/app_button.dart';

Widget _host(Widget child, {double width = 400}) => MaterialApp(
  home: Scaffold(
    body: Center(
      // Align loosens the constraints so content-sized buttons can be narrower.
      child: SizedBox(
        width: width,
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    ),
  ),
);

void main() {
  group('AppButton width policy', () {
    testWidgets('renders inside AlertDialog actions (intrinsic layout)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirm'),
                      actions: [
                        AppButton.outlined(text: 'Cancel', onPressed: () {}),
                        AppButton.primary(text: 'Confirm', onPressed: () {}),
                      ],
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Confirm'), findsNWidgets(2));
    });

    testWidgets('sizes to content inside an unbounded Row', (tester) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [AppButton.primary(text: 'Save', onPressed: () {})],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AppButton)).width, lessThan(400));
    });

    testWidgets('fills bounded width by default', (tester) async {
      await tester.pumpWidget(
        _host(AppButton.primary(text: 'Save', onPressed: () {})),
      );

      expect(tester.getSize(find.byType(AppButton)).width, 400);
    });

    testWidgets('isFullWidth false sizes to content', (tester) async {
      await tester.pumpWidget(
        _host(
          AppButton.primary(text: 'Save', onPressed: () {}, isFullWidth: false),
        ),
      );

      expect(tester.getSize(find.byType(AppButton)).width, lessThan(400));
    });

    testWidgets('responsive fills only below the compact breakpoint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(AppButton.responsive(text: 'Go', onPressed: () {}), width: 400),
      );
      expect(tester.getSize(find.byType(AppButton)).width, 400);

      await tester.pumpWidget(
        _host(AppButton.responsive(text: 'Go', onPressed: () {}), width: 800),
      );
      expect(tester.getSize(find.byType(AppButton)).width, lessThan(800));
    });
  });
}
