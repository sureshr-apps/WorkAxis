import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Remote organization reads and field writes. Thin seam over the data gateway so
/// the repository can be unit-tested with a fake. Status changes are not
/// here: they go through the `setOrganizationStatus` callable.
abstract interface class PlatformOrganizationsRemoteDataSource {
  Future<PageResult<CustomerOrganization>> listPage({
    required int limit,
    required int offset,
    String? nameContains,
    OrganizationStatus? status,
  });

  Future<OrganizationStatusCounts> statusCounts();

  /// The organization with branch/member counts and its administrators.
  Future<CustomerOrganization?> getById(String id);

  /// Inserts the organization (server assigns the id) and returns that id.
  Future<String> create(
    CreateOrganizationRequest request, {
    required String code,
  });

  Future<void> update(CustomerOrganization organization);

  /// `GetOrganizationLicense`: null when the organization has no license.
  Future<OrganizationLicense?> getLicense(String organizationId);

  /// `GetOrganizationLicenseHistory`, in the order the server returns it.
  Future<List<LicenseHistoryEvent>> getLicenseHistory(String organizationId);

  /// `ListLicensePlans` filtered to active plans.
  Future<List<LicensePlan>> listActiveLicensePlans();

  /// `AssignOrganizationLicense`.
  Future<void> assignLicense(
    String organizationId,
    AssignLicenseRequest request,
  );

  /// `ChangeOrganizationLicensePlan`.
  Future<void> changeLicensePlan(
    String organizationId,
    ChangeLicensePlanRequest request,
  );

  /// `ModifyOrganizationCommercialTerms`.
  Future<void> modifyCommercialTerms(
    String organizationId,
    ModifyCommercialTermsRequest request,
  );

  /// `RenewOrganizationLicense`.
  Future<void> renewLicense(String organizationId, RenewLicenseRequest request);
}
