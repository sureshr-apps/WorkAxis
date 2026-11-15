import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/widgets/form_action_row.dart';

Future<void> _pump(WidgetTester tester, {required double width}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: FormActionRow(
            submitLabel: 'Create Organization',
            submitIcon: Icons.add_circle_outline,
            onCancel: () {},
            onSubmit: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('keeps Cancel left of submit on one row at phone width', (
    tester,
  ) async {
    await _pump(tester, width: 360);

    final cancel = tester.getRect(find.text('Cancel'));
    final submit = tester.getRect(find.text('Create Organization'));
    expect(cancel.right, lessThan(submit.left));
    expect(cancel.top, closeTo(submit.top, 1));
    expect(submit.width, greaterThan(cancel.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps natural button widths on wide layouts', (tester) async {
    await _pump(tester, width: 900);

    final cancel = tester.getRect(find.text('Cancel'));
    final submit = tester.getRect(find.text('Create Organization'));
    expect(cancel.right, lessThan(submit.left));
    expect(submit.right, lessThan(900 - 16 + 1));
    expect(cancel.width, lessThan(200));
    expect(tester.takeException(), isNull);
  });
}
