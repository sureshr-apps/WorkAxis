import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/features/platform_organizations/data/organization_license_mapper.dart';
import 'package:workaxis/features/platform_organizations/data/platform_organizations_remote_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// [PlatformOrganizationsRemoteDataSource] backed by the data gateway
/// (`ListOrganizationsPaged`, `GetPlatformStats`, `GetOrganizationById`,
/// `GetOrganizationStats`, `ListMembersByOrgPaged`, `CreateOrganization`,
/// `UpdateOrganization` and the license operations).
class SqlConnectPlatformOrganizationsRemoteDataSource
    implements PlatformOrganizationsRemoteDataSource {
  SqlConnectPlatformOrganizationsRemoteDataSource({required this._gateway});

  final DataGateway _gateway;

  @override
  Future<PageResult<CustomerOrganization>> listPage({
    required int limit,
    required int offset,
    String? nameContains,
    OrganizationStatus? status,
  }) async {
    final data = await _gateway.call('ListOrganizationsPaged', {
      'limit': limit,
      'offset': offset,
      // Unset optional variables are omitted, never sent as null.
      if (nameContains != null && nameContains.trim().isNotEmpty)
        'nameContains': nameContains.trim(),
      'status': ?status?.name,
    });
    return PageResult(
      items: [
        for (final o in data.objects('organizations'))
          CustomerOrganization(
            id: o.string('id'),
            name: o.string('name'),
            code: o.string('code'),
            status: _status(o.string('status')),
            // Counts are fetched on the detail page, not for every list row.
            branchCount: null,
            employeeCount: null,
            createdAt: o.dateTime('createdAt'),
            category: _blankToNull(o.optString('category')),
          ),
      ],
      total: data.countOf('total'),
      offset: offset,
    );
  }

  @override
  Future<OrganizationStatusCounts> statusCounts() async {
    final data = await _gateway.call('GetPlatformStats');
    final counts = groupedCounts(
      data.objects('organizationsByStatus'),
      'status',
    );
    return OrganizationStatusCounts(
      active: counts['active'] ?? 0,
      suspended: counts['suspended'] ?? 0,
    );
  }

  @override
  Future<CustomerOrganization?> getById(String id) async {
    final (org, stats, admins) = await (
      _gateway.call('GetOrganizationById', {'id': id}),
      _gateway.call('GetOrganizationStats', {'orgId': id}),
      _gateway.call('ListMembersByOrgPaged', {
        'orgId': id,
        'limit': 50,
        'offset': 0,
        'role': 'orgAdmin',
      }),
    ).wait;
    final o = org.optObject('organization');
    if (o == null) return null;
    return CustomerOrganization(
      id: o.string('id'),
      name: o.string('name'),
      code: o.string('code'),
      status: _status(o.string('status')),
      branchCount: stats.countOf('branchCount'),
      employeeCount: stats.countOf('memberCount'),
      createdAt: o.dateTime('createdAt'),
      description: _blankToNull(o.optString('description')),
      category: _blankToNull(o.optString('category')),
      contactName: _blankToNull(o.optString('contactName')),
      contactEmail: _blankToNull(o.optString('contactEmail')),
      contactPhone: _blankToNull(o.optString('contactPhone')),
      address: _blankToNull(o.optString('address')),
      taxIdentification: _blankToNull(o.optString('taxIdentification')),
      admins: [
        for (final m in admins.objects('organizationMembers'))
          OrganizationAdminUser(
            id: m.string('id'),
            name: m.string('fullName'),
            email: LoginEmail.displayable(m.string('email')),
            phone: m.optString('phone') ?? '',
            username: m.string('username'),
            authUid: m.optString('authUid'),
            status: OrganizationAdminStatus.fromAccountName(m.string('status')),
          ),
      ],
    );
  }

  @override
  Future<OrganizationLicense?> getLicense(String organizationId) async {
    final data = await _gateway.call(
      'GetOrganizationLicense',
      OrganizationLicenseMapper.organizationVars(organizationId),
    );
    final license = data.optObject('organizationLicense');
    return license == null ? null : OrganizationLicenseMapper.license(license);
  }

  @override
  Future<List<LicenseHistoryEvent>> getLicenseHistory(
    String organizationId,
  ) async {
    final data = await _gateway.call(
      'GetOrganizationLicenseHistory',
      OrganizationLicenseMapper.organizationVars(organizationId),
    );
    return [
      for (final event in data.objects('licenseHistory'))
        OrganizationLicenseMapper.historyEvent(event),
    ];
  }

  @override
  Future<List<LicensePlan>> listActiveLicensePlans() async {
    final data = await _gateway.call(
      'ListLicensePlans',
      OrganizationLicenseMapper.listLicensePlansVars(status: PlanStatus.active),
    );
    return [
      for (final plan in data.objects('licensePlans'))
        OrganizationLicenseMapper.licensePlan(plan),
    ];
  }

  @override
  Future<void> assignLicense(
    String organizationId,
    AssignLicenseRequest request,
  ) async {
    await _gateway.call(
      'AssignOrganizationLicense',
      OrganizationLicenseMapper.assignVars(organizationId, request),
    );
  }

  @override
  Future<void> changeLicensePlan(
    String organizationId,
    ChangeLicensePlanRequest request,
  ) async {
    await _gateway.call(
      'ChangeOrganizationLicensePlan',
      OrganizationLicenseMapper.changePlanVars(organizationId, request),
    );
  }

  @override
  Future<void> modifyCommercialTerms(
    String organizationId,
    ModifyCommercialTermsRequest request,
  ) async {
    await _gateway.call(
      'ModifyOrganizationCommercialTerms',
      OrganizationLicenseMapper.modifyCommercialTermsVars(
        organizationId,
        request,
      ),
    );
  }

  @override
  Future<void> renewLicense(
    String organizationId,
    RenewLicenseRequest request,
  ) async {
    await _gateway.call(
      'RenewOrganizationLicense',
      OrganizationLicenseMapper.renewVars(organizationId, request),
    );
  }

  @override
  Future<String> create(
    CreateOrganizationRequest request, {
    required String code,
  }) async {
    final data = await _gateway.call('CreateOrganization', {
      'name': request.name.trim(),
      'code': code,
      'country': 'India',
      'currency': 'INR',
      'status': 'active',
      // Unset optional variables are omitted, never sent as null.
      if (_has(request.category)) 'category': request.category!.trim(),
      if (_has(request.description)) 'description': request.description!.trim(),
      if (_has(request.taxIdentification))
        'taxIdentification': request.taxIdentification!.trim(),
      if (_has(request.contactName)) 'contactName': request.contactName!.trim(),
      if (_has(request.contactEmail))
        'contactEmail': request.contactEmail!.trim(),
      if (_has(request.contactPhone))
        'contactPhone': request.contactPhone!.trim(),
      if (_has(request.address)) 'address': request.address!.trim(),
    });
    return data.object('organization_insert').string('id');
  }

  /// Writes every editable field; a blank value stores an empty string so the
  /// field can be cleared (reads map blank back to null).
  @override
  Future<void> update(CustomerOrganization organization) async {
    await _gateway.call('UpdateOrganization', {
      'id': organization.id,
      'name': organization.name.trim(),
      'category': (organization.category ?? '').trim(),
      'description': (organization.description ?? '').trim(),
      'taxIdentification': (organization.taxIdentification ?? '').trim(),
      'contactName': (organization.contactName ?? '').trim(),
      'contactEmail': (organization.contactEmail ?? '').trim(),
      'contactPhone': (organization.contactPhone ?? '').trim(),
      'address': (organization.address ?? '').trim(),
    });
  }

  bool _has(String? value) => value != null && value.trim().isNotEmpty;

  String? _blankToNull(String? value) => _has(value) ? value!.trim() : null;

  /// Unknown statuses map to suspended (fail closed).
  OrganizationStatus _status(String value) => switch (value) {
    'active' => OrganizationStatus.active,
    _ => OrganizationStatus.suspended,
  };
}
