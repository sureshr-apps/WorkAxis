import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';

/// Remote organization reads and field writes. Thin seam over SQL Connect so
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

  Future<OrganizationLicenseDetails?> getLicense(String organizationId);

  /// Inserts the organization (server assigns the id) and returns that id.
  Future<String> create(
    CreateOrganizationRequest request, {
    required String code,
  });

  Future<void> update(CustomerOrganization organization);
}
