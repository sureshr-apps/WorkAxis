import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/presentation/widgets/branch_access_panel.dart';

BranchRecord _branch({bool isActive = true}) => BranchRecord(
  summary: BranchSummary(
    id: 'br-1',
    organizationId: 'org-1',
    name: 'Downtown Flagship',
    code: 'BR-DT',
    location: 'Chicago',
    activeEmployeeCount: 12,
    isActive: isActive,
  ),
  geofenceRadiusMeters: 150,
  managerIds: const [],
  kioskStatus: KioskPairingStatus.notPaired,
);

class _Callbacks {
  int edits = 0;
  int toggles = 0;
  int deletes = 0;
}

Future<void> _pump(
  WidgetTester tester,
  BranchRecord branch,
  _Callbacks calls, {
  bool isUpdating = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: BranchAccessPanel(
            branch: branch,
            isUpdating: isUpdating,
            onEdit: () => calls.edits++,
            onToggleActive: () => calls.toggles++,
            onDelete: () => calls.deletes++,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an active branch offers Edit, Suspend and a delete icon', (
    tester,
  ) async {
    final calls = _Callbacks();
    await _pump(tester, _branch(), calls);

    expect(find.text('Branch access'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Suspend'), findsOneWidget);
    expect(find.text('Restore'), findsNothing);
    expect(find.byTooltip('Delete Downtown Flagship'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a suspended branch offers Restore instead of Suspend', (
    tester,
  ) async {
    final calls = _Callbacks();
    await _pump(tester, _branch(isActive: false), calls);

    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Suspend'), findsNothing);
  });

  testWidgets('each action calls its own callback', (tester) async {
    final calls = _Callbacks();
    await _pump(tester, _branch(), calls);

    await tester.tap(find.text('Edit'));
    await tester.tap(find.text('Suspend'));
    await tester.tap(find.byTooltip('Delete Downtown Flagship'));
    await tester.pumpAndSettle();

    expect(calls.edits, 1);
    expect(calls.toggles, 1);
    expect(calls.deletes, 1);
  });

  testWidgets('actions are disabled while a change is saving', (tester) async {
    final calls = _Callbacks();
    await _pump(tester, _branch(), calls, isUpdating: true);

    await tester.tap(find.text('Edit'), warnIfMissed: false);
    await tester.tap(
      find.byTooltip('Delete Downtown Flagship'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(calls.edits, 0);
    expect(calls.deletes, 0);
  });
}
