import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Contract for an organization's license: reads and the four license actions.
/// Platform users only. Every write is validated again by the server.
abstract interface class OrganizationLicenseRepository {
  /// The organization's license, or null when none has been assigned.
  Future<OrganizationLicense?> getLicense(String organizationId);

  /// History events, newest first.
  Future<List<LicenseHistoryEvent>> getHistory(String organizationId);

  /// Plans that may be assigned or selected (active plans only).
  Future<List<LicensePlan>> getActiveLicensePlans();

  Future<void> assignLicense(
    String organizationId,
    AssignLicenseRequest request,
  );

  Future<void> changePlan(
    String organizationId,
    ChangeLicensePlanRequest request,
  );

  Future<void> modifyCommercialTerms(
    String organizationId,
    ModifyCommercialTermsRequest request,
  );

  Future<void> renewLicense(String organizationId, RenewLicenseRequest request);
}
