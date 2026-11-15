import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/platform_organizations/data/mock_organization_license_store.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';

import '../../helpers/fixed_clock.dart';

/// The mock store follows the server rules, so these tests pin the behaviour
/// the UI relies on in every license state.
void main() {
  late MockOrganizationLicenseStore store;

  setUp(() {
    store = MockOrganizationLicenseStore(now: fixedNow);
  });

  test('seeds Acme on Plus with an active term; others are unlicensed', () {
    final license = store.getLicense('org-acme')!;
    expect(license.plan.name, 'Plus');
    expect(license.status, OrganizationLicenseStatus.active);
    expect(store.getLicense('org-crestline'), isNull);
    expect(
      store.getHistory('org-acme').single.eventType,
      LicenseEventType.assigned,
    );
  });

  test('only active plans are offered for assignment', () {
    expect(
      store.activePlans().map((p) => p.name),
      isNot(contains('Legacy Pilot')),
    );
  });

  test('assigning a future term reports Not Yet Active', () {
    store.assign(
      'org-crestline',
      AssignLicenseRequest(
        planId: 'plan-basic',
        startDate: DateTime.utc(2026, 11, 20),
        expiryDate: DateTime.utc(2027, 11, 19),
        negotiatedPrice: 50000,
        maintenancePrice: 5000,
      ),
    );
    expect(
      store.getLicense('org-crestline')!.status,
      OrganizationLicenseStatus.notYetActive,
    );
  });

  test('assigning to an inactive plan is refused', () {
    expect(
      () => store.assign(
        'org-crestline',
        AssignLicenseRequest(
          planId: 'plan-legacy',
          startDate: DateTime.utc(2026, 11, 7),
          expiryDate: DateTime.utc(2027, 11, 7),
          negotiatedPrice: 1,
          maintenancePrice: 1,
        ),
      ),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.userMessage,
          'userMessage',
          'Select an active license plan.',
        ),
      ),
    );
  });

  test(
    'changing to an active higher plan keeps the dates and writes plan_changed',
    () {
      store.changePlan(
        'org-acme',
        const ChangeLicensePlanRequest(
          targetPlanId: 'plan-enterprise',
          negotiatedPrice: 200000,
          maintenancePrice: 30000,
        ),
      );
      final license = store.getLicense('org-acme')!;
      expect(license.plan.name, 'Enterprise');
      expect(license.startDate, DateTime.utc(2026, 9, 8));
      expect(
        store.getHistory('org-acme').first.eventType,
        LicenseEventType.planChanged,
      );
    },
  );

  test('changing to an inactive or lower plan is refused', () {
    for (final target in ['plan-legacy', 'plan-basic']) {
      expect(
        () => store.changePlan(
          'org-acme',
          ChangeLicensePlanRequest(
            targetPlanId: target,
            negotiatedPrice: 1,
            maintenancePrice: 1,
          ),
        ),
        throwsA(isA<ValidationException>()),
        reason: target,
      );
    }
  });

  test('unchanged prices write no history row', () {
    final before = store.getHistory('org-acme').length;
    store.modifyCommercialTerms(
      'org-acme',
      const ModifyCommercialTermsRequest(
        negotiatedPrice: 120000,
        maintenancePrice: 18000,
      ),
    );
    expect(store.getHistory('org-acme'), hasLength(before));
  });

  test('changed prices write commercial_terms_modified', () {
    store.modifyCommercialTerms(
      'org-acme',
      const ModifyCommercialTermsRequest(
        negotiatedPrice: 125000,
        maintenancePrice: 18000,
      ),
    );
    final latest = store.getHistory('org-acme').first;
    expect(latest.eventType, LicenseEventType.commercialTermsModified);
    expect(latest.negotiatedPrice, 125000);
  });

  group('renewal', () {
    // Acme's term ends 2027-09-08 under the fixed clock (2026-11-07).
    test(
      'a back-to-back renewal keeps the running start and extends the expiry',
      () {
        store.renew(
          'org-acme',
          RenewLicenseRequest(
            planId: 'plan-plus',
            newStartDate: DateTime.utc(2027, 9, 9),
            newExpiryDate: DateTime.utc(2028, 9, 8),
            negotiatedPrice: 120000,
            maintenancePrice: 18000,
          ),
        );
        final license = store.getLicense('org-acme')!;
        expect(license.startDate, DateTime.utc(2026, 9, 8));
        expect(license.expiryDate, DateTime.utc(2028, 9, 8));
        expect(
          store.getHistory('org-acme').first.eventType,
          LicenseEventType.renewed,
        );
      },
    );

    test('a renewal after a gap takes the new start date', () {
      store.renew(
        'org-acme',
        RenewLicenseRequest(
          planId: 'plan-plus',
          newStartDate: DateTime.utc(2027, 10, 1),
          newExpiryDate: DateTime.utc(2028, 10, 1),
          negotiatedPrice: 120000,
          maintenancePrice: 18000,
        ),
      );
      final license = store.getLicense('org-acme')!;
      expect(license.startDate, DateTime.utc(2027, 10, 1));
      expect(license.expiryDate, DateTime.utc(2028, 10, 1));
    });

    test('a renewal that downgrades the plan is refused', () {
      expect(
        () => store.renew(
          'org-acme',
          RenewLicenseRequest(
            planId: 'plan-basic',
            newStartDate: DateTime.utc(2027, 9, 9),
            newExpiryDate: DateTime.utc(2028, 9, 8),
            negotiatedPrice: 1,
            maintenancePrice: 1,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  test('removing an organization drops its license', () {
    store.remove('org-acme');
    expect(store.getLicense('org-acme'), isNull);
    expect(store.getHistory('org-acme'), isEmpty);
  });
}
