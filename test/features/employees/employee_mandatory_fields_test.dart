import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/employees/domain/models/member_field.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/employee_demographics_section.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/employee_employment_section.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/member_form_feedback.dart';

const _required = MemberFormFeedback(
  required: {
    MemberField.aadhaarNumber,
    MemberField.aadhaarPhoto,
    MemberField.designation,
    MemberField.salary,
  },
);

void main() {
  group('Employee Demographics & Employment mandatory indicators', () {
    testWidgets(
      'demographics section reflects mandatory requirement on labels',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmployeeDemographicsSection(
                  aadhaarController: TextEditingController(),
                  addressController: TextEditingController(),
                  aadhaarPhotoPath: null,
                  onAadhaarPhotoChanged: (_) {},
                  dateOfBirth: null,
                  onDateOfBirthChanged: (_) {},
                  gender: 'Male',
                  onGenderChanged: (_) {},
                  feedback: _required,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Aadhaar Number *'), findsOneWidget);
        expect(find.text('Aadhaar Card Document Photo *'), findsOneWidget);
      },
    );

    testWidgets('employment section reflects mandatory requirement on labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmployeeEmploymentSection(
                designationController: TextEditingController(),
                salaryController: TextEditingController(),
                joiningDate: DateTime(2025, 1, 1),
                onJoiningDateChanged: (_) {},
                relievingDate: null,
                onRelievingDateChanged: (_) {},
                assetsController: TextEditingController(),
                feedback: _required,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Designation *'), findsOneWidget);
      expect(find.text('Monthly Salary *'), findsOneWidget);
    });

    testWidgets('optional labels when not mandatory', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  EmployeeDemographicsSection(
                    aadhaarController: TextEditingController(),
                    addressController: TextEditingController(),
                    aadhaarPhotoPath: null,
                    onAadhaarPhotoChanged: (_) {},
                    dateOfBirth: null,
                    onDateOfBirthChanged: (_) {},
                    gender: 'Male',
                    onGenderChanged: (_) {},
                    feedback: MemberFormFeedback.none,
                  ),
                  EmployeeEmploymentSection(
                    designationController: TextEditingController(),
                    salaryController: TextEditingController(),
                    joiningDate: DateTime(2025, 1, 1),
                    onJoiningDateChanged: (_) {},
                    relievingDate: null,
                    onRelievingDateChanged: (_) {},
                    assetsController: TextEditingController(),
                    feedback: MemberFormFeedback.none,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Aadhaar Number'), findsOneWidget);
      expect(find.text('Aadhaar Card Document Photo'), findsOneWidget);
      expect(find.text('Designation'), findsOneWidget);
      expect(find.text('Monthly Salary'), findsOneWidget);
    });
  });
}
