import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_license_tab.dart';

import '../../helpers/fixed_clock.dart';

OrganizationLicenseDetails _license(DateTime expiry) =>
    OrganizationLicenseDetails(
      planName: 'Basic',
      status: 'Active',
      level: 1,
      agreementId: 'AGR-ORG-1',
      agreementStart: DateTime(2025, 11, 7),
      agreementExpiry: expiry,
      maximumStores: 10,
      maximumUsers: 50,
      negotiatedPrice: 40000,
      annualMaintenancePrice: 5000,
      history: [
        LicenseHistoryEntry(
          event: 'License Assigned',
          occurredAt: DateTime(2025, 11, 7, 10, 45),
          planName: 'Basic',
          level: 1,
          periodStart: DateTime(2025, 11, 7),
          periodEnd: expiry,
          stores: 10,
          users: 50,
          negotiatedPrice: 40000,
          annualMaintenancePrice: 5000,
        ),
      ],
    );

Future<void> _pumpTab(
  WidgetTester tester,
  OrganizationLicenseDetails license,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: OrganizationLicenseTab(
            license: license,
            onAction: (_) {},
            now: fixedNow,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('expiry label covers future, today and expired licenses', () {
    String label(DateTime expiry) =>
        LicenseFormatters.expiryLabel(_license(expiry), testNow);

    expect(label(DateTime(2026, 11, 17)), 'Expires in 10 days (2026-11-17)');
    expect(label(DateTime(2026, 11, 8)), 'Expires in 1 day (2026-11-08)');
    expect(label(DateTime(2026, 11, 7)), 'Expires today (2026-11-07)');
    expect(label(DateTime(2026, 11, 2)), 'Expired 5 days ago (2026-11-02)');
  });

  testWidgets('shows "Expired N days ago" for a lapsed license', (
    tester,
  ) async {
    await _pumpTab(
      tester,
      _license(DateTime(2026, 11, 2)),
      const Size(1280, 900),
    );

    expect(find.text('Expired 5 days ago (2026-11-02)'), findsOneWidget);
    expect(find.textContaining('Expires in'), findsNothing);
  });

  for (final entry in const {
    'desktop': Size(1280, 900),
    'tablet': Size(768, 1024),
    'compact': Size(390, 844),
  }.entries) {
    testWidgets('license tab lays out without overflow on ${entry.key}', (
      tester,
    ) async {
      await _pumpTab(tester, _license(DateTime(2026, 11, 17)), entry.value);
      expect(tester.takeException(), isNull);
      expect(find.text('LICENSE HISTORY'), findsOneWidget);
    });
  }
}
