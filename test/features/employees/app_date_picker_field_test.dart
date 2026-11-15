import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/app_date_picker_field.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/employee_demographics_section.dart';

void main() {
  group('AppDatePickerField Tests', () {
    testWidgets('renders label, formatted text, and responds to tap', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppDatePickerField(
              label: 'Date of Birth',
              valueText: '15 Aug 1995',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('15 Aug 1995'), findsOneWidget);
      await tester.tap(find.text('15 Aug 1995'));
      expect(tapped, isTrue);
    });

    testWidgets('renders clear icon and calls onClear when value is present', (
      tester,
    ) async {
      bool cleared = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppDatePickerField(
              label: 'Relieving Date',
              valueText: '31 Dec 2024',
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsOneWidget);
      await tester.tap(find.byIcon(Icons.clear));
      expect(cleared, isTrue);
    });
  });

  group('EmployeeDemographicsSection Sizing Tests', () {
    testWidgets(
      'Date of Birth and Gender boxes have identical heights and widths in row layout',
      (tester) async {
        final aadhaarController = TextEditingController();
        final addressController = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmployeeDemographicsSection(
                  aadhaarController: aadhaarController,
                  addressController: addressController,
                  aadhaarPhotoPath: null,
                  onAadhaarPhotoChanged: (_) {},
                  dateOfBirth: DateTime(1996, 5, 20),
                  onDateOfBirthChanged: (_) {},
                  gender: 'Male',
                  onGenderChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final dobFinder = find.byType(AppDatePickerField);
        final genderDropdownFinder = find.byType(
          DropdownButtonFormField<String?>,
        );

        expect(dobFinder, findsOneWidget);
        expect(genderDropdownFinder, findsOneWidget);

        final dobInputDecorator = find.descendant(
          of: dobFinder,
          matching: find.byType(InputDecorator),
        );
        final genderInputDecorator = find.descendant(
          of: genderDropdownFinder,
          matching: find.byType(InputDecorator),
        );

        final dobFieldSize = tester.getSize(dobInputDecorator);
        final genderFieldSize = tester.getSize(genderInputDecorator);

        // Verify that the input boxes have identical visual height and width
        expect(dobFieldSize.height, equals(genderFieldSize.height));
        expect(dobFieldSize.width, equals(genderFieldSize.width));
      },
    );
  });
}
