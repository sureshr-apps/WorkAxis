import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_card_item.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_session_details_card.dart';

import 'night_shift_fixtures.dart';

void main() {
  Future<void> pumpBody(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets('a session card explains a system-closed night shift', (
    tester,
  ) async {
    await pumpBody(
      tester,
      AttendanceSessionDetailsCard(
        index: 1,
        entry: nightShift(
          checkoutStatus: CheckoutStatus.missing,
          sessionClosedAt: ist(7, 13),
          correctionStatus: CorrectionStatus.pending,
        ),
        branchName: 'Downtown',
        canReview: false,
        isSaving: false,
        onReview: null,
      ),
    );

    expect(find.text('Shift 9:00 PM – 5:00 AM (next day)'), findsOneWidget);
    expect(find.text('Missing'), findsOneWidget);
    expect(find.text('Missing check-out'), findsOneWidget);
    expect(find.text('Correction pending review'), findsOneWidget);
    expect(
      find.textContaining('Closed by system at Nov 7, 2026 1:00 PM'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a day card shows overdue check-out and pending overtime', (
    tester,
  ) async {
    final summary = AttendanceDaySummary.fromEntries([
      nightShift(id: 'a', checkoutStatus: CheckoutStatus.overdue),
      nightShift(
        id: 'b',
        checkOutAt: ist(6, 22),
        potentialOvertimeHours: 2,
        overtimeStatus: OvertimeStatus.pending,
      ),
    ]).single;
    await pumpBody(
      tester,
      AttendanceCardItem(
        summary: summary,
        branchNames: 'Downtown',
        onDetails: () {},
      ),
    );

    expect(find.text('Last out: Overdue'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('2h potential OT · Pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
