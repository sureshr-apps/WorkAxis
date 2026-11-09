import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/platform_organizations/data/platform_organizations_remote_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_draft.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_admin_rules.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_validator.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';

/// Production [PlatformOrganizationsRepository].
///
/// Reads and field writes use SQL Connect through the remote data source
/// (server-side filters, pagination and aggregate counts). Status changes use
/// the `setOrganizationStatus` callable because suspension must also revoke
/// every member's access. Methods return what the server saved.
class SqlConnectPlatformOrganizationsRepository
    implements PlatformOrganizationsRepository {
  SqlConnectPlatformOrganizationsRepository({
    required this._dataSource,
    required this._functions,
  });

  final PlatformOrganizationsRemoteDataSource _dataSource;
  final CallableFunctions _functions;
  late final AccountCallables _accounts = AccountCallables(_functions);
  final Map<String, String> _pendingAdminRequestIds = {};

  @override
  Future<PageResult<CustomerOrganization>> getOrganizationsPage({
    String? query,
    OrganizationStatus? statusFilter,
    int offset = 0,
    int limit = defaultPageSize,
  }) => _guard(
    () => _dataSource.listPage(
      limit: limit,
      offset: offset,
      nameContains: query,
      status: statusFilter,
    ),
  );

  @override
  Future<OrganizationStatusCounts> getStatusCounts() =>
      _guard(_dataSource.statusCounts);

  @override
  Future<CustomerOrganization?> getOrganizationById(String id) =>
      _guard(() => _dataSource.getById(id));

  @override
  Future<OrganizationLicenseDetails?> getOrganizationLicenseDetails(
    String organizationId,
  ) => _guard(() => _dataSource.getLicense(organizationId));

  @override
  Future<CustomerOrganization> createOrganization(
    CreateOrganizationRequest request,
  ) => _guard(() async {
    OrganizationValidator.validate(
      name: request.name,
      contactEmail: request.contactEmail,
    );
    final id = await _dataSource.create(
      request,
      code: 'ORG-${RequestIds.shortCode(6)}',
    );
    return _require(id);
  });

  @override
  Future<CustomerOrganization> updateOrganization(
    CustomerOrganization organization,
  ) => _guard(() async {
    OrganizationValidator.validate(
      name: organization.name,
      contactEmail: organization.contactEmail,
    );
    await _dataSource.update(organization);
    return _require(organization.id);
  });

  @override
  Future<CustomerOrganization> updateOrganizationStatus(
    String id,
    OrganizationStatus newStatus,
  ) => _guard(() async {
    final response = await _functions.call('setOrganizationStatus', {
      'organizationId': id,
      'status': newStatus.name,
    });
    final failed = response['membersFailed'];
    if (failed is int && failed > 0) {
      throw DatabaseException(
        'setOrganizationStatus left $failed members unsynchronized',
        userMessage:
            'The organization status changed, but $failed member accounts '
            'could not be updated. Try the change again to finish.',
      );
    }
    return _require(id);
  });

  @override
  Future<CustomerOrganization> createOrganizationAdmin(
    String organizationId,
    OrganizationAdminDraft draft,
  ) => _guard(() async {
    OrganizationAdminRules.validate(draft, isCreate: true);
    final username = draft.username.trim().toLowerCase();
    final requestId = _pendingAdminRequestIds.putIfAbsent(
      '$organizationId/$username',
      RequestIds.uuidV4,
    );
    await _accounts.provision(
      requestId: requestId,
      fullName: draft.name.trim(),
      username: username,
      email: _blankToNull(draft.email)?.toLowerCase(),
      phone: ContactValidators.normalizePhone(draft.phone),
      password: draft.initialPassword!,
      role: UserRole.orgAdmin,
      organizationId: organizationId,
    );
    _pendingAdminRequestIds.remove('$organizationId/$username');
    return _require(organizationId);
  });

  @override
  Future<CustomerOrganization> updateOrganizationAdmin(
    String organizationId,
    OrganizationAdminUser administrator,
  ) => _guard(() async {
    final draft = OrganizationAdminDraft(
      name: administrator.name,
      username: administrator.username ?? '',
      email: administrator.email,
      phone: administrator.phone,
    );
    OrganizationAdminRules.validate(draft, isCreate: false);
    final org = await _require(organizationId);
    final existing = _admin(org, administrator.id);
    final nextEmail = administrator.email.trim().toLowerCase();
    final nextPhone = ContactValidators.normalizePhone(administrator.phone);
    await _accounts.update(
      targetUid: _uid(existing),
      fullName: administrator.name.trim(),
      email: nextEmail != existing.email.toLowerCase() ? nextEmail : null,
      clearEmail: nextEmail.isEmpty && existing.email.isNotEmpty,
      phone: nextPhone != null && nextPhone != existing.phone
          ? nextPhone
          : null,
      clearPhone: existing.phone.isNotEmpty && nextPhone == null,
    );
    return _require(organizationId);
  });

  @override
  Future<void> resetOrganizationAdminPassword({
    required String organizationId,
    required String adminId,
    required String newPassword,
  }) => _guard(() async {
    final passwordError = ContactValidators.password(newPassword);
    if (passwordError != null) throw ValidationException(passwordError);
    final org = await _require(organizationId);
    await _accounts.resetPassword(
      targetUid: _uid(_admin(org, adminId)),
      newPassword: newPassword,
    );
  });

  @override
  Future<CustomerOrganization> setOrganizationAdminStatus(
    String organizationId,
    String adminId,
    OrganizationAdminStatus status,
  ) => _guard(() async {
    final org = await _require(organizationId);
    final admin = _admin(org, adminId);
    OrganizationAdminRules.checkStatusChange(org.admins, adminId, status);
    await _accounts.setStatus(
      targetUid: _uid(admin),
      status: status == OrganizationAdminStatus.active
          ? AccountStatus.active
          : AccountStatus.suspended,
    );
    return _require(organizationId);
  });

  OrganizationAdminUser _admin(CustomerOrganization org, String adminId) {
    for (final admin in org.admins) {
      if (admin.id == adminId) return admin;
    }
    throw const NotFoundException('Administrator not found');
  }

  String _uid(OrganizationAdminUser admin) {
    final uid = admin.authUid;
    if (uid == null || uid.isEmpty) {
      throw ValidationException(
        'This account has no sign-in identity yet and cannot be changed here.',
      );
    }
    return uid;
  }

  String? _blankToNull(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  Future<CustomerOrganization> _require(String id) async {
    final org = await _dataSource.getById(id);
    if (org == null) {
      throw const NotFoundException('Organization not found');
    }
    return org;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
