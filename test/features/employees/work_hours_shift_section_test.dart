import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/work_hours_shift_section.dart';

void main() {
  group('WorkHoursShiftSection Widget & Bidirectional Sync Tests', () {
    late TextEditingController workHoursController;
    late TextEditingController shiftHoursController;

    setUp(() {
      workHoursController = TextEditingController();
      shiftHoursController = TextEditingController();
    });

    tearDown(() {
      workHoursController.dispose();
      shiftHoursController.dispose();
    });

    Future<void> pumpSection(
      WidgetTester tester, {
      double initialWorkHours = 8.0,
      String? initialShiftHours = '09:00 AM - 05:00 PM',
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WorkHoursShiftSection(
                workHoursController: workHoursController,
                shiftHoursController: shiftHoursController,
                initialWorkHours: initialWorkHours,
                initialShiftHours: initialShiftHours,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('initializes with default 9:00 AM start time and 8.0 hours', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(workHoursController.text, '8');
      expect(shiftHoursController.text, '09:00 AM - 05:00 PM');
      expect(find.text('09:00 AM'), findsOneWidget);
      expect(find.text('05:00 PM'), findsOneWidget);
      expect(find.text('Shift Start'), findsOneWidget);
      expect(find.text('Shift End'), findsOneWidget);
    });

    testWidgets(
      'adjusting work hours adjusts end time only and preserves 9:00 AM start time',
      (tester) async {
        await pumpSection(tester);

        // Change work hours from 8 to 6
        workHoursController.text = '6';
        await tester.pumpAndSettle();

        // 9:00 AM + 6h = 03:00 PM
        expect(shiftHoursController.text, '09:00 AM - 03:00 PM');
        expect(find.text('09:00 AM'), findsOneWidget);
        expect(find.text('03:00 PM'), findsOneWidget);

        // Change work hours to 9.5
        workHoursController.text = '9.5';
        await tester.pumpAndSettle();

        // 9:00 AM + 9.5h = 06:30 PM
        expect(shiftHoursController.text, '09:00 AM - 06:30 PM');
        expect(find.text('09:00 AM'), findsOneWidget);
        expect(find.text('06:30 PM'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping quick preset chips updates work hours and adjusts end time',
      (tester) async {
        await pumpSection(tester);

        // Tap '4 hrs' chip
        await tester.tap(find.text('4 hrs'));
        await tester.pumpAndSettle();

        expect(workHoursController.text, '4');
        expect(shiftHoursController.text, '09:00 AM - 01:00 PM');
        expect(find.text('01:00 PM'), findsOneWidget);

        // Tap '10 hrs' chip
        await tester.tap(find.text('10 hrs'));
        await tester.pumpAndSettle();

        expect(workHoursController.text, '10');
        expect(shiftHoursController.text, '09:00 AM - 07:00 PM');
        expect(find.text('07:00 PM'), findsOneWidget);
      },
    );

    testWidgets(
      'editing shift window text automatically recalculates work hours',
      (tester) async {
        await pumpSection(tester);

        // Change shift window range to 10:00 AM - 06:00 PM (8 hours)
        shiftHoursController.text = '10:00 AM - 06:00 PM';
        await tester.pumpAndSettle();

        expect(workHoursController.text, '8');
        expect(find.text('10:00 AM'), findsOneWidget);
        expect(find.text('06:00 PM'), findsOneWidget);

        // Change shift window range to 08:00 AM - 02:00 PM (6 hours)
        shiftHoursController.text = '08:00 AM - 02:00 PM';
        await tester.pumpAndSettle();

        expect(workHoursController.text, '6');
        expect(find.text('08:00 AM'), findsOneWidget);
        expect(find.text('02:00 PM'), findsOneWidget);
      },
    );

    testWidgets(
      'handles cross-midnight shift windows (e.g. 10:00 PM - 06:00 AM)',
      (tester) async {
        await pumpSection(tester);

        shiftHoursController.text = '10:00 PM - 06:00 AM';
        await tester.pumpAndSettle();

        // 10:00 PM to 6:00 AM is 8 hours
        expect(workHoursController.text, '8');
        expect(find.text('10:00 PM'), findsOneWidget);
        expect(find.text('06:00 AM'), findsOneWidget);
      },
    );
  });
}
