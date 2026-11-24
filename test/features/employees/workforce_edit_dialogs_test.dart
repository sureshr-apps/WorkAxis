import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/employees/domain/models/employee_workforce_history.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/workforce_edit_dialogs.dart';

void main() {
  final today = DateTime(2026, 11, 23);

  // Sunday off until 1 Jan 2027, then a future version with Saturday off.
  final current = ScheduleVersion(
    id: 'current',
    effectiveFrom: DateTime(2026, 11, 1),
    effectiveTo: DateTime(2027, 1, 1),
    dailyWorkHours: 8,
    shiftHours: '09:00 AM - 05:00 PM',
    weeklyDaysOff: const [0],
  );
  final future = ScheduleVersion(
    id: 'future',
    effectiveFrom: DateTime(2027, 1, 1),
    dailyWorkHours: 8,
    shiftHours: '09:00 AM - 05:00 PM',
    weeklyDaysOff: const [6],
  );
  // Newest first, as the history API returns them.
  final schedules = [future, current];

  /// Picks [date] in the effective-from date picker using text input.
  Future<void> pickEffectiveFrom(WidgetTester tester, String date) async {
    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, date);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  /// Opens [dialog] from a button and records what the dialog popped with.
  Future<List<bool?>> open(WidgetTester tester, Widget dialog) async {
    final results = <bool?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => results.add(
                await showDialog<bool>(
                  context: context,
                  builder: (_) => dialog,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('salary dialog cannot be dismissed while saving and closes '
      'cleanly after a successful save', (tester) async {
    final pending = Completer<void>();
    SalaryDraft? saved;
    final results = await open(
      tester,
      SalaryEditDialog(
        businessToday: today,
        onSave: (draft) {
          saved = draft;
          return pending.future;
        },
      ),
    );

    await tester.enterText(find.byType(TextField), '25000');
    await tester.tap(find.text('Save salary'));
    await tester.pump();

    // Tapping the barrier while the save is in flight keeps the dialog open.
    await tester.tapAt(const Offset(5, 5));
    // The spinner animates while saving, so pump past the dismiss animation.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SalaryEditDialog), findsOneWidget);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SalaryEditDialog), findsNothing);
    expect(results, [true]);
    expect(saved, (effectiveFrom: '2026-11-23', monthlySalary: 25000.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule dialog keeps the entry and shows a safe error when the '
      'save fails', (tester) async {
    await open(
      tester,
      ScheduleEditDialog(
        businessToday: today,
        onSave: (_) => Future.error(StateError('db host=10.0.0.5 down')),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '7.5');
    await tester.tap(find.text('Save schedule'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleEditDialog), findsOneWidget);
    expect(find.text('The schedule could not be saved.'), findsOneWidget);
    expect(find.textContaining('10.0.0.5'), findsNothing);
    expect(find.text('7.5'), findsOneWidget);
  });

  testWidgets('schedule dialog validates hours before saving', (tester) async {
    var calls = 0;
    await open(
      tester,
      ScheduleEditDialog(businessToday: today, onSave: (_) async => calls++),
    );

    await tester.enterText(find.byType(TextField).first, '30');
    await tester.tap(find.text('Save schedule'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.text('Enter work hours between 0.5 and 24.'), findsOneWidget);
  });

  test('scheduleInForceOn finds the version covering a day', () {
    expect(scheduleInForceOn(schedules, today)?.id, 'current');
    expect(scheduleInForceOn(schedules, DateTime(2026, 12, 31))?.id, 'current');
    expect(scheduleInForceOn(schedules, DateTime(2027, 1, 1))?.id, 'future');
    expect(scheduleInForceOn(schedules, DateTime(2026, 10, 31)), isNull);
    expect(scheduleInForceOn(const [], today), isNull);
  });

  testWidgets('schedule dialog starts with the days off in force on the '
      'effective date, not those of a future version', (tester) async {
    ScheduleDraft? saved;
    await open(
      tester,
      ScheduleEditDialog(
        businessToday: today,
        schedules: schedules,
        onSave: (draft) async => saved = draft,
      ),
    );

    expect(find.text('Sunday'), findsOneWidget);
    await tester.tap(find.text('Save schedule'));
    await tester.pumpAndSettle();
    expect(saved?.weeklyDaysOff, [0]);
  });

  testWidgets('changing the effective date refreshes the days off until the '
      'admin edits them', (tester) async {
    ScheduleDraft? saved;
    await open(
      tester,
      ScheduleEditDialog(
        businessToday: today,
        schedules: schedules,
        onSave: (draft) async => saved = draft,
      ),
    );

    await pickEffectiveFrom(tester, '01/05/2027');
    expect(find.text('Saturday'), findsOneWidget);

    // Edit the days off: add Sunday to Saturday.
    await tester.tap(find.text('Saturday'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Sunday'));
    await tester.pumpAndSettle();
    // Close the menu by tapping the field again.
    await tester.tap(find.text('Sunday, Saturday'));
    await tester.pumpAndSettle();

    // A later date change keeps the edited days.
    await pickEffectiveFrom(tester, '12/01/2026');
    await tester.tap(find.text('Save schedule'));
    await tester.pumpAndSettle();
    expect(saved?.effectiveFrom, '2026-12-01');
    expect(saved?.weeklyDaysOff, [0, 6]);
  });
}
