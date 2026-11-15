import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_card.dart';

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

Future<void> _pump(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: 360, child: card),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping anywhere on the card opens the branch', (tester) async {
    var opened = 0;
    await _pump(tester, BranchCard(branch: _branch(), onOpen: () => opened++));

    await tester.tap(find.text('Downtown Flagship'));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets(
    'has no View details button and shows a chevron beside the status',
    (tester) async {
      await _pump(tester, BranchCard(branch: _branch(), onOpen: () {}));

      expect(find.text('View details'), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    },
  );

  testWidgets(
    'shows edit, suspend and delete only when those actions are given',
    (tester) async {
      await _pump(tester, BranchCard(branch: _branch(), onOpen: () {}));
      expect(find.byTooltip('Edit Downtown Flagship'), findsNothing);
      expect(find.byTooltip('Suspend Downtown Flagship'), findsNothing);
      expect(find.byTooltip('Delete Downtown Flagship'), findsNothing);

      var edits = 0;
      var toggles = 0;
      var deletes = 0;
      await _pump(
        tester,
        BranchCard(
          branch: _branch(),
          onOpen: () {},
          onEdit: () => edits++,
          onToggleActive: () => toggles++,
          onDelete: () => deletes++,
        ),
      );
      await tester.tap(find.byTooltip('Edit Downtown Flagship'));
      await tester.tap(find.byTooltip('Suspend Downtown Flagship'));
      await tester.tap(find.byTooltip('Delete Downtown Flagship'));

      expect(edits, 1);
      expect(toggles, 1);
      expect(deletes, 1);
    },
  );

  testWidgets('a suspended branch offers reactivation', (tester) async {
    await _pump(
      tester,
      BranchCard(
        branch: _branch(isActive: false),
        onOpen: () {},
        onToggleActive: () {},
      ),
    );

    expect(find.byTooltip('Reactivate Downtown Flagship'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
  });
}
