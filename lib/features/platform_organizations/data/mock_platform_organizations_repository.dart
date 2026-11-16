import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/core/storage/mock_attachment_storage.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_draft.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_admin_rules.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_validator.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Mock repository implementation for Platform Customer Organizations.
/// Applies the same validation as production.
class MockPlatformOrganizationsRepository
    implements PlatformOrganizationsRepository {
  final MockPlatformOrganizationsDataSource _dataSource;

  MockPlatformOrganizationsRepository({
    MockPlatformOrganizationsDataSource? dataSource,
    AttachmentStorage? attachments,
  }) : _dataSource = dataSource ?? MockPlatformOrganizationsDataSource(),
       _attachments = attachments ?? const MockAttachmentStorage();

  final AttachmentStorage _attachments;

  MockPlatformOrganizationsDataSource get dataSource => _dataSource;

  @override
  Future<PageResult<CustomerOrganization>> getOrganizationsPage({
    String? query,
    OrganizationStatus? statusFilter,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    final all = _dataSource.getOrganizations(
      query: query,
      statusFilter: statusFilter,
    );
    final start = offset.clamp(0, all.length);
    final end = (offset + limit).clamp(0, all.length);
    return PageResult(
      items: all.sublist(start, end),
      total: all.length,
      offset: start,
    );
  }

  @override
  Future<OrganizationStatusCounts> getStatusCounts() async {
    final all = _dataSource.getOrganizations();
    return OrganizationStatusCounts(
      active: all.where((o) => o.status.isActive).length,
      suspended: all.where((o) => o.status.isSuspended).length,
    );
  }

  @override
  Future<CustomerOrganization?> getOrganizationById(String id) async {
    return _dataSource.getById(id);
  }

  @override
  Future<OrganizationLicense?> getLicense(String organizationId) async =>
      _dataSource.licenses.getLicense(organizationId);

  @override
  Future<List<LicenseHistoryEvent>> getHistory(String organizationId) async =>
      _dataSource.licenses.getHistory(organizationId);

  @override
  Future<List<LicensePlan>> getActiveLicensePlans() async =>
      _dataSource.licenses.activePlans();

  @override
  Future<void> assignLicense(
    String organizationId,
    AssignLicenseRequest request,
  ) async => _dataSource.licenses.assign(organizationId, request);

  @override
  Future<void> changePlan(
    String organizationId,
    ChangeLicensePlanRequest request,
  ) async => _dataSource.licenses.changePlan(organizationId, request);

  @override
  Future<void> modifyCommercialTerms(
    String organizationId,
    ModifyCommercialTermsRequest request,
  ) async =>
      _dataSource.licenses.modifyCommercialTerms(organizationId, request);

  @override
  Future<void> renewLicense(
    String organizationId,
    RenewLicenseRequest request,
  ) async => _dataSource.licenses.renew(organizationId, request);

  @override
  Future<CustomerOrganization> createOrganization(
    CreateOrganizationRequest request,
  ) async {
    OrganizationValidator.validate(
      name: request.name,
      contactEmail: request.contactEmail,
    );
    return _dataSource.create(request);
  }

  @override
  Future<CustomerOrganization> updateOrganization(
    CustomerOrganization organization,
  ) async {
    OrganizationValidator.validate(
      name: organization.name,
      contactEmail: organization.contactEmail,
    );
    return _dataSource.update(organization);
  }

  @override
  Future<CustomerOrganization> updateOrganizationStatus(
    String id,
    OrganizationStatus newStatus,
  ) async {
    return _dataSource.setStatus(id, newStatus);
  }

  @override
  Future<CustomerOrganization> updateOrganizationLogo(
    String organizationId,
    String localPath,
  ) async {
    final current = await getOrganizationById(organizationId);
    if (current == null) {
      throw NotFoundException('Organization not found');
    }
    final reference = await _attachments.upload(
      localPath: localPath,
      organizationId: organizationId,
      kind: AttachmentKind.organizationLogo,
    );
    return updateOrganization(current.copyWith(logoUrl: reference));
  }

  @override
  Future<void> deleteOrganization(String id) async {
    _dataSource.delete(id);
  }

  @override
  Future<CustomerOrganization> createOrganizationAdmin(
    String organizationId,
    OrganizationAdminDraft draft,
  ) async {
    OrganizationAdminRules.validate(draft, isCreate: true);
    return _dataSource.createAdmin(organizationId, draft);
  }

  @override
  Future<CustomerOrganization> updateOrganizationAdmin(
    String organizationId,
    OrganizationAdminUser administrator,
  ) async {
    OrganizationAdminRules.validate(
      OrganizationAdminDraft(
        name: administrator.name,
        username: administrator.username ?? '',
        email: administrator.email,
        phone: administrator.phone,
      ),
      isCreate: false,
    );
    return _dataSource.updateAdmin(organizationId, administrator);
  }

  @override
  Future<void> resetOrganizationAdminPassword({
    required String organizationId,
    required String adminId,
    required String newPassword,
  }) async {
    final error = ContactValidators.password(newPassword);
    if (error != null) throw ValidationException(error);
    final org = _dataSource.getById(organizationId);
    if (org == null || !org.admins.any((a) => a.id == adminId)) {
      throw ValidationException('Administrator not found.');
    }
  }

  @override
  Future<CustomerOrganization> setOrganizationAdminStatus(
    String organizationId,
    String adminId,
    OrganizationAdminStatus status,
  ) async {
    final org = _dataSource.getById(organizationId);
    if (org != null) {
      OrganizationAdminRules.checkStatusChange(org.admins, adminId, status);
    }
    return _dataSource.setAdminStatus(organizationId, adminId, status);
  }
}
