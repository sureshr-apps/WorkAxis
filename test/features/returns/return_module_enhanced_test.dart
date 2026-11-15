import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/app_date_picker_field.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_details_dialog.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_image_picker.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/submit_return_dialog.dart';

void main() {
  group('Return Reason Enum Tests', () {
    test('supports all 5 user reasons plus other with clean display names', () {
      expect(ReturnReason.damaged.displayName, 'Damaged');
      expect(ReturnReason.rotten.displayName, 'Rotten');
      expect(ReturnReason.wrongItem.displayName, 'Wrong Item');
      expect(ReturnReason.customerReturned.displayName, 'Customer Returned');
      expect(ReturnReason.expired.displayName, 'Expired');
      expect(ReturnReason.other.displayName, 'Other');

      // Parsing tests
      expect(ReturnReason.parse('rotten'), ReturnReason.rotten);
      expect(ReturnReason.parse('damaged'), ReturnReason.damaged);
      expect(ReturnReason.parse('wrong item'), ReturnReason.wrongItem);
      expect(
        ReturnReason.parse('customer returned'),
        ReturnReason.customerReturned,
      );
      expect(ReturnReason.parse('expired'), ReturnReason.expired);
    });
  });

  group('SubmitReturnDialog Enhanced Fields Tests', () {
    const branches = [
      BranchSummary(
        id: 'br-01',
        organizationId: 'org-1',
        name: 'Downtown Flagship',
        code: 'DF-01',
        location: 'Downtown',
      ),
      BranchSummary(
        id: 'br-02',
        organizationId: 'org-1',
        name: 'Westside Hub',
        code: 'WH-02',
        location: 'Westside',
      ),
    ];

    testWidgets(
      'submits complete return payload with bill, invoice, date, reason, quantity, image',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        CreateReturnInput? submittedInput;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SubmitReturnDialog(
                availableBranches: branches,
                initialBranchId: 'br-01',
                onSubmit: (input) async {
                  submittedInput = input;
                  return null;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify all field headers and inputs exist
        expect(find.text('Record Return'), findsOneWidget);
        expect(find.text('Branch *'), findsOneWidget);
        expect(find.text('Product Name *'), findsOneWidget);
        expect(find.text('Quantity *'), findsOneWidget);
        expect(find.text('Return Reason *'), findsOneWidget);
        expect(find.text('Bill Number *'), findsOneWidget);
        expect(find.text('Invoice Number *'), findsOneWidget);
        expect(find.text('Return Date *'), findsOneWidget);
        expect(find.byType(AppDatePickerField), findsOneWidget);
        expect(find.byType(ReturnImagePicker), findsOneWidget);

        // Enter Product Name
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'e.g. Kashmiri Apples (Batch #FA-902), Robusta Bananas',
          ),
          'Alphonso Mangoes 5kg',
        );

        // Enter Quantity
        await tester.enterText(
          find.widgetWithText(TextField, 'e.g. 5.5'),
          '10.5',
        );

        // Enter Bill Number
        await tester.enterText(
          find.widgetWithText(TextField, 'e.g. BILL-4092'),
          'BILL-7721',
        );

        // Enter Invoice Number
        await tester.enterText(
          find.widgetWithText(TextField, 'e.g. INV-2026-8812'),
          'INV-9901',
        );

        // Select 'Rotten' reason
        await tester.tap(find.text('Damaged')); // current initial dropdown text
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rotten').last);
        await tester.pumpAndSettle();

        // Submit
        await tester.tap(find.text('Submit Return'));
        await tester.pumpAndSettle();

        expect(submittedInput, isNotNull);
        expect(submittedInput!.productTitle, 'Alphonso Mangoes 5kg');
        expect(submittedInput!.quantity, 10.5);
        expect(submittedInput!.unit, 'kg');
        expect(submittedInput!.reason, ReturnReason.rotten);
        expect(submittedInput!.billNumber, 'BILL-7721');
        expect(submittedInput!.invoiceNumber, 'INV-9901');
        expect(submittedInput!.branchId, 'br-01');
      },
    );

    testWidgets(
      'supports multi-item return from 1 bill with dynamic row addition and removal',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        CreateReturnBatchInput? submittedBatch;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SubmitReturnDialog(
                availableBranches: branches,
                initialBranchId: 'br-01',
                onSubmitBatch: (batch) async {
                  submittedBatch = batch;
                  return null;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter Bill Number
        await tester.enterText(
          find.widgetWithText(TextField, 'e.g. BILL-4092'),
          'BILL-10492',
        );

        // Enter Item #1 details (e.g. Apples - Rotten)
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'e.g. Kashmiri Apples (Batch #FA-902), Robusta Bananas',
          ),
          'Royal Gala Apples',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'e.g. 5.5'),
          '1.5',
        );

        // Select 'Rotten' for Item #1
        await tester.tap(find.text('Damaged').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rotten').last);
        await tester.pumpAndSettle();

        // Verify currently 1 item
        expect(find.text('1 item'), findsOneWidget);
        expect(find.text('Submit Return'), findsOneWidget);

        // Tap "+ Add Another Item"
        await tester.tap(find.text('+ Add Another Item from this Bill'));
        await tester.pumpAndSettle();

        // Now 2 items
        expect(find.text('2 items'), findsOneWidget);
        expect(find.text('Item #1'), findsOneWidget);
        expect(find.text('Item #2'), findsOneWidget);
        expect(find.text('Submit Return (2 items)'), findsOneWidget);

        // Enter Item #2 details (e.g. Papaya - 2 units - Damaged)
        final productFields = find.widgetWithText(
          TextField,
          'e.g. Kashmiri Apples (Batch #FA-902), Robusta Bananas',
        );
        expect(productFields, findsNWidgets(2));
        await tester.enterText(productFields.at(1), 'Papaya');

        final quantityFields = find.widgetWithText(TextField, 'e.g. 5.5');
        expect(quantityFields, findsNWidgets(2));
        await tester.enterText(quantityFields.at(1), '2');

        // Submit
        await tester.tap(find.text('Submit Return (2 items)'));
        await tester.pumpAndSettle();

        expect(submittedBatch, isNotNull);
        expect(submittedBatch!.billNumber, 'BILL-10492');
        expect(submittedBatch!.invoiceNumber, 'BILL-10492');
        expect(submittedBatch!.items.length, 2);

        // Check Item #1
        expect(submittedBatch!.items[0].productTitle, 'Royal Gala Apples');
        expect(submittedBatch!.items[0].quantity, 1.5);
        expect(submittedBatch!.items[0].unit, 'kg');
        expect(submittedBatch!.items[0].reason, ReturnReason.rotten);

        // Check Item #2
        expect(submittedBatch!.items[1].productTitle, 'Papaya');
        expect(submittedBatch!.items[1].quantity, 2.0);
        expect(submittedBatch!.items[1].reason, ReturnReason.damaged);
      },
    );
  });

  group('ReturnDetailsDialog Image & Details Tests', () {
    final testItem = ReturnItem(
      id: 'RET-881',
      organizationId: 'org-1',
      branchId: 'br-01',
      branchName: 'Downtown Flagship',
      employeeId: 'emp-1',
      employeeName: 'Sarah Connor',
      productTitle: 'Organic Strawberries',
      reason: ReturnReason.rotten,
      quantity: 4.0,
      unit: 'boxes',
      billNumber: 'BILL-5501',
      invoiceNumber: 'INV-5501',
      returnDate: DateTime(2026, 11, 14),
      status: ReturnStatus.pending,
      billImageUrl: 'https://storage.googleapis.com/test/bill.png',
      remarks: 'Fungus growth visible on bottom box layers.',
    );

    testWidgets(
      'renders all details including Rotten reason, bill, invoice, and photo badge',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: ReturnDetailsDialog(item: testItem)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Return Request #RET-881'), findsOneWidget);
        expect(find.text('Organic Strawberries'), findsOneWidget);
        expect(find.text('4 boxes'), findsOneWidget);
        expect(find.text('Rotten'), findsOneWidget);
        expect(find.text('BILL-5501'), findsOneWidget);
        expect(find.text('INV-5501'), findsOneWidget);
        expect(
          find.text('Fungus growth visible on bottom box layers.'),
          findsOneWidget,
        );
        expect(find.text('Proof Photo Verified'), findsOneWidget);
        expect(find.text('View Full'), findsOneWidget);
      },
    );
  });
}
