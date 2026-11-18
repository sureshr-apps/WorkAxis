import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_card.dart';

BranchRecord _branch() => BranchRecord(
  summary: const BranchSummary(
    id: 'br-1',
    organizationId: 'org-1',
    name: 'Downtown Flagship',
    code: 'BR-DT',
    location: 'Chicago',
    activeEmployeeCount: 12,
    isActive: true,
  ),
  geofenceRadiusMeters: 150,
  managerIds: const [],
  kioskStatus: KioskPairingStatus.notPaired,
);

void main() {
  testWidgets('branch card actions sit at the right edge of the card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 360,
              child: BranchCard(
                branch: _branch(),
                onOpen: () {},
                onEdit: () {},
                onToggleActive: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byKey(const Key('branch-card-br-1')));
    final delete = tester.getRect(find.text('Delete'));
    // The last action should end close to the card's right padding (16dp),
    // not in the middle of the footer.
    expect(card.right - delete.right, lessThan(32));
    expect(tester.takeException(), isNull);
  });
}
