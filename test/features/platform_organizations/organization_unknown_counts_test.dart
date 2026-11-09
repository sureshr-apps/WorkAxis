import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_card_item.dart';

void main() {
  testWidgets('unknown list counts appear unavailable instead of zero', (
    tester,
  ) async {
    final org = CustomerOrganization(
      id: 'org',
      name: 'Organization',
      code: 'ORG',
      status: OrganizationStatus.active,
      branchCount: null,
      employeeCount: null,
      createdAt: DateTime(2026),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationCardItem(
            organization: org,
            onTap: () {},
            onEdit: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('0'), findsNothing);
    expect(find.text('null'), findsNothing);
  });
}
