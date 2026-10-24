import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';

/// Mock repository implementation for Platform Customer Organizations.
class MockPlatformOrganizationsRepository
    implements PlatformOrganizationsRepository {
  final MockPlatformOrganizationsDataSource _dataSource;

  MockPlatformOrganizationsRepository({
    MockPlatformOrganizationsDataSource? dataSource,
  }) : _dataSource = dataSource ?? MockPlatformOrganizationsDataSource();

  MockPlatformOrganizationsDataSource get dataSource => _dataSource;

  @override
  Future<List<CustomerOrganization>> getOrganizations({
    String? query,
    OrganizationStatus? statusFilter,
  }) async {
    return _dataSource.getOrganizations(
      query: query,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<CustomerOrganization?> getOrganizationById(String id) async {
    return _dataSource.getById(id);
  }

  @override
  Future<OrganizationLicenseDetails?> getOrganizationLicenseDetails(
    String organizationId,
  ) async {
    return _dataSource.getLicenseDetails(organizationId);
  }

  @override
  Future<CustomerOrganization> createOrganization(
    CreateOrganizationRequest request,
  ) async {
    return _dataSource.create(request);
  }

  @override
  Future<CustomerOrganization> updateOrganization(
    CustomerOrganization organization,
  ) async {
    return _dataSource.update(organization);
  }

  @override
  Future<CustomerOrganization> updateOrganizationStatus(
    String id,
    OrganizationStatus newStatus,
  ) async {
    return _dataSource.setStatus(id, newStatus);
  }
}
