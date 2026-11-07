import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';
import 'package:workaxis/features/organization_dashboard/presentation/attention_item_presentation.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/widgets/attention_item_card.dart';
import 'package:workaxis/shared/widgets/attendance_summary_card.dart';

void main() {
  const attendance = AttendanceSummary(
    present: 8,
    late: 1,
    absent: 1,
    totalScheduled: 10,
  );

  Future<void> pump(WidgetTester tester, Widget child, Size size) async {
    tester.view.physicalSize = size;
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

  for (final size in const [Size(390, 844), Size(768, 1024), Size(1280, 800)]) {
    testWidgets('AttendanceSummaryCard shows no fabricated data at $size', (
      tester,
    ) async {
      await pump(
        tester,
        const AttendanceSummaryCard(attendance: attendance),
        size,
      );
      expect(find.textContaining('Target'), findsNothing);
      expect(find.textContaining('Updated'), findsNothing);
      expect(find.textContaining('Central Distribution Hub'), findsNothing);
      expect(find.textContaining('Key Branch Adherence'), findsNothing);
      expect(find.text('Attendance rate: 80% of 10 scheduled'), findsOneWidget);
      expect(find.text('Not tracked'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('branch snapshots are rendered only from data', (tester) async {
    await pump(
      tester,
      const AttendanceSummaryCard(
        attendance: attendance,
        branchSnapshots: [
          BranchAdherenceSnapshot(
            code: 'AB',
            name: 'Alpha Branch',
            details: '8 of 10 present',
            adherenceRate: 0.8,
            adherencePercentage: '80.0%',
          ),
        ],
      ),
      const Size(1280, 800),
    );
    expect(find.text('Alpha Branch'), findsOneWidget);
    expect(find.text('80.0%'), findsOneWidget);
  });

  group('AttentionItemCard', () {
    const item = AttentionItem(
      id: '1',
      kind: AttentionKind.shiftTransfers,
      severity: AttentionSeverity.neutral,
      title: 'Shift transfers',
      subtitle: '',
      details: 'Two pending',
      statusLabel: 'Open',
      timestamp: '',
    );

    testWidgets('action is disabled with no destination', (tester) async {
      await pump(
        tester,
        const AttentionItemCard(item: item),
        const Size(390, 844),
      );
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('action fires when a destination exists', (tester) async {
      var taps = 0;
      await pump(
        tester,
        AttentionItemCard(item: item, onAction: () => taps++),
        const Size(390, 844),
      );
      await tester.tap(find.byType(OutlinedButton));
      expect(taps, 1);
    });

    test('routes resolve per scope and unrouted kinds are null', () {
      const returns = AttentionItem(
        id: '2',
        kind: AttentionKind.pendingReturns,
        severity: AttentionSeverity.pending,
        title: 't',
        subtitle: '',
        details: '',
        statusLabel: '',
        timestamp: '',
      );
      expect(returns.routeFor(branchScope: true), '/branch-manager/returns');
      expect(returns.routeFor(branchScope: false), '/organization/returns');
      expect(item.routeFor(branchScope: false), isNull);
    });
  });

  test('BranchAdherenceSnapshot threshold lives in the model', () {
    const on = BranchAdherenceSnapshot(
      code: 'A',
      name: 'A',
      details: '',
      adherenceRate: 0.90,
      adherencePercentage: '90%',
    );
    const off = BranchAdherenceSnapshot(
      code: 'B',
      name: 'B',
      details: '',
      adherenceRate: 0.89,
      adherencePercentage: '89%',
    );
    expect(on.isOnTarget, isTrue);
    expect(off.isOnTarget, isFalse);
  });
}
