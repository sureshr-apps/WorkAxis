import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/features/platform_organizations/data/mock_organization_license_store.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/organization_license_controller.dart';

import '../../helpers/fixed_clock.dart';

/// Repository whose license reads always fail, to test the error state.
class _UnreachableLicenseRepository
    extends MockPlatformOrganizationsRepository {
  @override
  Future<OrganizationLicense?> getLicense(String organizationId) =>
      Future.error(DatabaseException('connection refused 10.0.0.5'));
}

MockPlatformOrganizationsRepository _repository() =>
    MockPlatformOrganizationsRepository(
      dataSource: MockPlatformOrganizationsDataSource(
        licenses: MockOrganizationLicenseStore(now: fixedNow),
      ),
    );

void main() {
  group('loading', () {
    test('loads the license, history and active plans together', () async {
      final controller = OrganizationLicenseController(
        repository: _repository(),
      );

      await controller.load('org-acme');

      expect(controller.isLoadingFor('org-acme'), isFalse);
      expect(controller.licenseFor('org-acme')!.plan.name, 'Plus');
      expect(controller.historyFor('org-acme'), hasLength(1));
      expect(
        controller.activePlans.map((p) => p.name),
        containsAll(['Basic', 'Plus', 'Enterprise']),
      );
      expect(
        controller.activePlans.map((p) => p.name),
        isNot(contains('Legacy Pilot')),
      );
    });

    test('an organization without a license loads with no license', () async {
      final controller = OrganizationLicenseController(
        repository: _repository(),
      );

      await controller.load('org-crestline');

      expect(controller.licenseFor('org-crestline'), isNull);
      expect(controller.historyFor('org-crestline'), isEmpty);
      expect(controller.errorFor('org-crestline'), isNull);
    });

    test(
      'a switch to another organization never exposes the previous license',
      () async {
        final controller = OrganizationLicenseController(
          repository: _repository(),
        );
        await controller.load('org-acme');

        await controller.load('org-crestline');

        expect(controller.licenseFor('org-acme'), isNull);
        expect(controller.licenseFor('org-crestline'), isNull);
      },
    );

    test(
      'a failed read shows a safe message, not the technical error',
      () async {
        final controller = OrganizationLicenseController(
          repository: _UnreachableLicenseRepository(),
        );

        await controller.load('org-acme');

        final message = controller.errorFor('org-acme');
        expect(message, isNotNull);
        expect(message, isNot(contains('10.0.0.5')));
        expect(controller.isLoadingFor('org-acme'), isFalse);
      },
    );
  });

  group('actions', () {
    test('a successful change re-reads the license and returns null', () async {
      final controller = OrganizationLicenseController(
        repository: _repository(),
      );
      await controller.load('org-acme');

      final failure = await controller.modifyCommercialTerms(
        const ModifyCommercialTermsRequest(
          negotiatedPrice: 130000,
          maintenancePrice: 18000,
        ),
      );

      expect(failure, isNull);
      expect(controller.licenseFor('org-acme')!.negotiatedPrice, 130000);
      expect(controller.historyFor('org-acme').first.negotiatedPrice, 130000);
    });

    test(
      'a refused change returns the server message and keeps the license',
      () async {
        final controller = OrganizationLicenseController(
          repository: _repository(),
        );
        await controller.load('org-acme');

        final failure = await controller.changePlan(
          const ChangeLicensePlanRequest(
            targetPlanId: 'plan-basic',
            negotiatedPrice: 1,
            maintenancePrice: 1,
          ),
        );

        expect(failure, 'Only a higher-level active plan can be selected.');
        expect(controller.licenseFor('org-acme')!.plan.name, 'Plus');
      },
    );

    test(
      'assigning twice is refused with the existing-license message',
      () async {
        final controller = OrganizationLicenseController(
          repository: _repository(),
        );
        await controller.load('org-acme');

        final failure = await controller.assignLicense(
          AssignLicenseRequest(
            planId: 'plan-basic',
            startDate: DateTime.utc(2026, 11, 7),
            expiryDate: DateTime.utc(2027, 11, 7),
            negotiatedPrice: 1,
            maintenancePrice: 1,
          ),
        );

        expect(failure, 'This organization already has a license.');
      },
    );

    test(
      'a renewal that starts before the current expiry is refused',
      () async {
        final controller = OrganizationLicenseController(
          repository: _repository(),
        );
        await controller.load('org-acme');
        final expiry = controller.licenseFor('org-acme')!.expiryDate;

        final failure = await controller.renewLicense(
          RenewLicenseRequest(
            planId: 'plan-plus',
            newStartDate: expiry,
            newExpiryDate: expiry.add(const Duration(days: 365)),
            negotiatedPrice: 1,
            maintenancePrice: 1,
          ),
        );

        expect(
          failure,
          'The new start date must be after the current expiry date '
          '(${CalendarDate.format(expiry)}).',
        );
      },
    );

    test('an action without a loaded organization reports failure', () async {
      final controller = OrganizationLicenseController(
        repository: _repository(),
      );

      final failure = await controller.modifyCommercialTerms(
        const ModifyCommercialTermsRequest(
          negotiatedPrice: 1,
          maintenancePrice: 1,
        ),
      );

      expect(failure, isNotNull);
    });
  });

  test('clear drops every piece of license state', () async {
    final controller = OrganizationLicenseController(repository: _repository());
    await controller.load('org-acme');

    controller.clear();

    expect(controller.organizationId, isNull);
    expect(controller.licenseFor('org-acme'), isNull);
    expect(controller.activePlans, isEmpty);
  });
}
