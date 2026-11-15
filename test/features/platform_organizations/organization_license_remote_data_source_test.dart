import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/platform_organizations/data/sql_connect_platform_organizations_remote_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

import '../../helpers/fake_data_gateway.dart';

Map<String, dynamic> _plan({
  String id = 'plan-plus',
  String status = 'active',
}) => {
  'id': id,
  'planCode': 'PLN-1A2B3C4D5E6F-PLUS',
  'name': 'Plus',
  'level': 2,
  'maxStores': 10,
  'maxUsers': 50,
  'status': status,
  'description': '',
  'assignedOrganizations': 1,
};

Map<String, dynamic> _license({String status = 'expiring_soon'}) => {
  'id': 'lic-1',
  'organizationId': 'org1',
  'planId': 'plan-plus',
  'startDate': '2025-11-07',
  'expiryDate': '2026-11-17',
  'negotiatedPrice': 120000,
  'maintenancePrice': 18000.5,
  'status': status,
  'plan': _plan(),
};

Map<String, dynamic> _event({
  String eventType = 'plan_changed',
  String eventAt = '2026-11-07T05:15:00.000Z',
}) => {
  'id': 'hist-1',
  'eventType': eventType,
  'eventAt': eventAt,
  'planId': 'plan-plus',
  'planCode': 'PLN-1A2B3C4D5E6F-PLUS',
  'planName': 'Plus',
  'planLevel': 2,
  'maxStores': 10,
  'maxUsers': 50,
  'startDate': '2025-11-07',
  'expiryDate': '2026-11-17',
  'negotiatedPrice': 120000,
  'maintenancePrice': 18000,
};

void main() {
  late FakeDataGateway gateway;
  late SqlConnectPlatformOrganizationsRemoteDataSource source;

  setUp(() {
    gateway = FakeDataGateway();
    source = SqlConnectPlatformOrganizationsRemoteDataSource(gateway: gateway);
  });

  group('reads', () {
    test(
      'getLicense calls GetOrganizationLicense and maps the license',
      () async {
        gateway.respond('GetOrganizationLicense', {
          'organizationLicense': _license(),
        });

        final license = (await source.getLicense('org1'))!;

        expect(gateway.singleVarsOf('GetOrganizationLicense'), {
          'organizationId': 'org1',
        });
        expect(license.id, 'lic-1');
        expect(license.organizationId, 'org1');
        expect(license.startDate, DateTime.utc(2025, 11, 7));
        expect(license.expiryDate, DateTime.utc(2026, 11, 17));
        expect(license.negotiatedPrice, 120000);
        expect(license.maintenancePrice, 18000.5);
        expect(license.status, OrganizationLicenseStatus.expiringSoon);
        expect(license.plan.name, 'Plus');
        expect(license.plan.level, 2);
        expect(license.plan.status, PlanStatus.active);
      },
    );

    test(
      'getLicense returns null when the organization has no license',
      () async {
        gateway.respond('GetOrganizationLicense', {
          'organizationLicense': null,
        });
        expect(await source.getLicense('org1'), isNull);
      },
    );

    test('an unknown license status is a malformed response', () async {
      gateway.respond('GetOrganizationLicense', {
        'organizationLicense': _license(status: 'frozen'),
      });
      await expectLater(
        source.getLicense('org1'),
        throwsA(isA<DatabaseException>()),
      );
    });

    test(
      'getLicenseHistory calls GetOrganizationLicenseHistory and maps events',
      () async {
        gateway.respond('GetOrganizationLicenseHistory', {
          'licenseHistory': [
            _event(eventType: 'commercial_terms_modified'),
            _event(eventType: 'renewed', eventAt: '2026-01-01T00:00:00.000Z'),
          ],
        });

        final history = await source.getLicenseHistory('org1');

        expect(gateway.singleVarsOf('GetOrganizationLicenseHistory'), {
          'organizationId': 'org1',
        });
        expect(history.map((e) => e.eventType), [
          LicenseEventType.commercialTermsModified,
          LicenseEventType.renewed,
        ]);
        expect(history.first.planName, 'Plus');
        expect(history.first.planLevel, 2);
        expect(history.first.startDate, DateTime.utc(2025, 11, 7));
        expect(history.first.eventAt, DateTime.utc(2026, 11, 7, 5, 15));
      },
    );

    test(
      'listActiveLicensePlans filters ListLicensePlans to active plans',
      () async {
        gateway.respond('ListLicensePlans', {
          'licensePlans': [_plan()],
          'summary': {'totalPlans': 1},
        });

        final plans = await source.listActiveLicensePlans();

        expect(gateway.singleVarsOf('ListLicensePlans'), {'status': 'active'});
        expect(plans.single, isA<LicensePlan>());
        expect(plans.single.name, 'Plus');
        expect(plans.single.status, PlanStatus.active);
      },
    );
  });

  group('writes', () {
    test(
      'assignLicense sends AssignOrganizationLicense with calendar dates',
      () async {
        gateway.respond('AssignOrganizationLicense', {
          'organizationLicense_insert': {'id': 'lic-1'},
        });

        await source.assignLicense(
          'org1',
          AssignLicenseRequest(
            planId: 'plan-plus',
            startDate: DateTime.utc(2026, 11, 7),
            expiryDate: DateTime.utc(2027, 11, 7),
            negotiatedPrice: 120000,
            maintenancePrice: 18000,
          ),
        );

        expect(gateway.singleVarsOf('AssignOrganizationLicense'), {
          'organizationId': 'org1',
          'planId': 'plan-plus',
          'startDate': '2026-11-07',
          'expiryDate': '2027-11-07',
          'negotiatedPrice': 120000,
          'maintenancePrice': 18000,
        });
      },
    );

    test('changeLicensePlan sends ChangeOrganizationLicensePlan', () async {
      gateway.respond('ChangeOrganizationLicensePlan', {
        'organizationLicense_update': {'id': 'lic-1'},
      });

      await source.changeLicensePlan(
        'org1',
        const ChangeLicensePlanRequest(
          targetPlanId: 'plan-enterprise',
          negotiatedPrice: 200000,
          maintenancePrice: 30000,
        ),
      );

      expect(gateway.singleVarsOf('ChangeOrganizationLicensePlan'), {
        'organizationId': 'org1',
        'targetPlanId': 'plan-enterprise',
        'negotiatedPrice': 200000,
        'maintenancePrice': 30000,
      });
    });

    test(
      'modifyCommercialTerms sends ModifyOrganizationCommercialTerms',
      () async {
        gateway.respond('ModifyOrganizationCommercialTerms', {
          'organizationLicense_update': {'id': 'lic-1'},
        });

        await source.modifyCommercialTerms(
          'org1',
          const ModifyCommercialTermsRequest(
            negotiatedPrice: 125000,
            maintenancePrice: 18000,
          ),
        );

        expect(gateway.singleVarsOf('ModifyOrganizationCommercialTerms'), {
          'organizationId': 'org1',
          'negotiatedPrice': 125000,
          'maintenancePrice': 18000,
        });
      },
    );

    test('renewLicense sends the back-to-back dates as entered', () async {
      // The current term ends 2026-11-06. Starting 2026-11-07 is the contiguous
      // case: the server keeps the current start date and extends the expiry.
      gateway.respond('RenewOrganizationLicense', {
        'organizationLicense_update': {'id': 'lic-1'},
      });

      await source.renewLicense(
        'org1',
        RenewLicenseRequest(
          planId: 'plan-plus',
          newStartDate: DateTime.utc(2026, 11, 7),
          newExpiryDate: DateTime.utc(2027, 11, 7),
          negotiatedPrice: 120000,
          maintenancePrice: 18000,
        ),
      );

      expect(gateway.singleVarsOf('RenewOrganizationLicense'), {
        'organizationId': 'org1',
        'planId': 'plan-plus',
        'newStartDate': '2026-11-07',
        'newExpiryDate': '2027-11-07',
        'negotiatedPrice': 120000,
        'maintenancePrice': 18000,
      });
    });

    test('renewLicense sends a gapped renewal start unchanged', () async {
      gateway.respond('RenewOrganizationLicense', {
        'organizationLicense_update': {'id': 'lic-1'},
      });

      await source.renewLicense(
        'org1',
        RenewLicenseRequest(
          planId: 'plan-enterprise',
          newStartDate: DateTime.utc(2026, 12, 1),
          newExpiryDate: DateTime.utc(2027, 12, 1),
          negotiatedPrice: 1,
          maintenancePrice: 0,
        ),
      );

      final vars = gateway.singleVarsOf('RenewOrganizationLicense');
      expect(vars['newStartDate'], '2026-12-01');
      expect(vars['newExpiryDate'], '2027-12-01');
    });
  });
}
