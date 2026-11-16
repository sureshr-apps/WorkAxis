import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_overview_tab.dart';

CustomerOrganization _org() => CustomerOrganization(
  id: 'org',
  name: 'Apple',
  code: 'ORG-1',
  status: OrganizationStatus.active,
  branchCount: 1,
  employeeCount: 2,
  createdAt: DateTime(2026, 11, 14),
);

Future<void> _pump(WidgetTester tester, {VoidCallback? onDelete}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OrganizationOverviewTab(
            organization: _org(),
            onUpload: () {},
            onDelete: onDelete,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a delete icon beside the Active label', (tester) async {
    await _pump(tester, onDelete: () {});

    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.byTooltip('Delete organization'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the delete icon calls onDelete', (tester) async {
    var deletes = 0;
    await _pump(tester, onDelete: () => deletes++);

    await tester.tap(find.byTooltip('Delete organization'));
    expect(deletes, 1);
  });

  testWidgets('hides the delete icon when no handler is given', (tester) async {
    await _pump(tester);

    expect(find.byTooltip('Delete organization'), findsNothing);
  });
}
