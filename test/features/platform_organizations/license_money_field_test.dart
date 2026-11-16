import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/license_form_fields.dart';

void main() {
  testWidgets('the rupee sign sits on the same line as the amount', (
    tester,
  ) async {
    final controller = TextEditingController(text: '75000');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: LicenseMoneyField(
              label: 'Negotiated price',
              controller: controller,
              enabled: true,
              // A message makes the field taller; a widget prefix then drifts
              // away from the amount's line.
              errorText: 'Enter a valid amount.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rupee = tester.getCenter(find.textContaining('₹'));
    final amount = tester.getCenter(find.byType(EditableText));
    expect((rupee.dy - amount.dy).abs(), lessThan(2));
    expect(tester.takeException(), isNull);
  });
}
