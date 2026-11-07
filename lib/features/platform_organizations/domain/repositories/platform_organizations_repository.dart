import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_draft.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';

/// Organization counts per status (platform-wide, unaffected by list filters).
class OrganizationStatusCounts {
  const OrganizationStatusCounts({
    required this.active,
    required this.suspended,
  });

  final int active;
  final int suspended;
  int get total => active + suspended;
}

/// Contract for managing platform customer organizations.
abstract interface class PlatformOrganizationsRepository {
  /// One page of organizations filtered on the server by name and status.
  Future<PageResult<CustomerOrganization>> getOrganizationsPage({
    String? query,
    OrganizationStatus? statusFilter,
    int offset = 0,
    int limit = defaultPageSize,
  });

  /// Platform-wide counts per status.
  Future<OrganizationStatusCounts> getStatusCounts();

  /// Retrieves a single organization with its branch/member counts and
  /// administrators.
  Future<CustomerOrganization?> getOrganizationById(String id);

  /// Retrieves the license and commercial terms for one organization.
  Future<OrganizationLicenseDetails?> getOrganizationLicenseDetails(
    String organizationId,
  );

  /// Creates a customer organization; returns what the server saved.
  Future<CustomerOrganization> createOrganization(
    CreateOrganizationRequest request,
  );

  /// Updates the editable details of an organization (not its status) and
  /// returns what the server saved.
  Future<CustomerOrganization> updateOrganization(
    CustomerOrganization organization,
  );

  /// Suspends or reactivates an organization and its members' sign-in access.
  Future<CustomerOrganization> updateOrganizationStatus(
    String id,
    OrganizationStatus newStatus,
  );

  /// Creates an Organization Admin account in [organizationId] through the
  /// account callables; returns the organization with its refreshed admins.
  /// Email and phone are optional; the initial password is required.
  Future<CustomerOrganization> createOrganizationAdmin(
    String organizationId,
    OrganizationAdminDraft draft,
  );

  /// Updates an administrator's name, email and phone (the username is fixed
  /// after creation). Returns the organization with refreshed admins.
  Future<CustomerOrganization> updateOrganizationAdmin(
    String organizationId,
    OrganizationAdminUser administrator,
  );

  /// Sets a new password for [adminId]. The password is never stored.
  Future<void> resetOrganizationAdminPassword({
    required String organizationId,
    required String adminId,
    required String newPassword,
  });

  /// Suspends or reactivates [adminId]. Suspending the last active
  /// administrator is rejected with a `ValidationException`.
  Future<CustomerOrganization> setOrganizationAdminStatus(
    String organizationId,
    String adminId,
    OrganizationAdminStatus status,
  );
}
