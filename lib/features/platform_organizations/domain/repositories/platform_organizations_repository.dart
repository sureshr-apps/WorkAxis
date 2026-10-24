import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';

/// Contract for managing platform customer organizations.
abstract interface class PlatformOrganizationsRepository {
  /// Retrieves organizations optionally filtered by search text and status.
  Future<List<CustomerOrganization>> getOrganizations({
    String? query,
    OrganizationStatus? statusFilter,
  });

  /// Retrieves a single organization by its unique ID.
  Future<CustomerOrganization?> getOrganizationById(String id);

  /// Retrieves the license and commercial terms for one organization.
  Future<OrganizationLicenseDetails?> getOrganizationLicenseDetails(
    String organizationId,
  );

  /// Creates and registers a new customer organization.
  Future<CustomerOrganization> createOrganization(
    CreateOrganizationRequest request,
  );

  /// Updates details for an existing customer organization.
  Future<CustomerOrganization> updateOrganization(
    CustomerOrganization organization,
  );

  /// Changes the operational status of an organization (e.g. suspend or reactivate).
  Future<CustomerOrganization> updateOrganizationStatus(
    String id,
    OrganizationStatus newStatus,
  );
}
