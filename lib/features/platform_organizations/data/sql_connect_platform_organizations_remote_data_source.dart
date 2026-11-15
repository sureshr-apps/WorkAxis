import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/features/platform_organizations/data/platform_organizations_remote_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/license_event_parser.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';

/// [PlatformOrganizationsRemoteDataSource] backed by the data gateway
/// (`ListOrganizationsPaged`, `GetPlatformStats`, `GetOrganizationById`,
/// `GetOrganizationStats`, `ListMembersByOrgPaged`,
/// `GetCommercialAgreementByOrg`, `ListLicenseEventsByOrg`,
/// `CreateOrganization`, `UpdateOrganization`).
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
  Future<OrganizationLicenseDetails?> getLicense(String organizationId) async {
    final (agreements, events, org) = await (
      _gateway.call('GetCommercialAgreementByOrg', {'orgId': organizationId}),
      _gateway.call('ListLicenseEventsByOrg', {'orgId': organizationId}),
      _gateway.call('GetOrganizationById', {'id': organizationId}),
    ).wait;
    final agreement = agreements.objects('commercialAgreements').firstOrNull;
    if (agreement == null) return null;

    final history = [
      for (final e in events.objects('licenseEvents')) _historyEntry(e),
    ];
    return OrganizationLicenseDetails(
      planName: agreement.string('planName'),
      status: agreement.string('status'),
      level: LicenseEventParser.level(agreement.string('planTier')) ?? 1,
      agreementId: agreement.string('agreementReference'),
      agreementStart: agreement.dateOnly('startDate'),
      agreementExpiry: agreement.dateOnly('expiryDate'),
      maximumStores: agreement.integer('maxStores'),
      maximumUsers: agreement.integer('maxUsers'),
      negotiatedPrice: agreement.number('negotiatedPrice'),
      annualMaintenancePrice: agreement.number('annualMaintenancePrice'),
      currencyCode:
          org.optObject('organization')?.optString('currency') ?? 'INR',
      history: history,
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

  LicenseHistoryEntry _historyEntry(Map<String, dynamic> e) {
    final occurredAt = e.dateTime('createdAt');
    final period = LicenseEventParser.period(e.string('validityPeriod'));
    return LicenseHistoryEntry(
      event: e.string('eventType'),
      occurredAt: occurredAt,
      planName: e.string('planName'),
      level: LicenseEventParser.level(e.string('planTier')) ?? 1,
      periodStart: period?.start ?? occurredAt,
      periodEnd: period?.end ?? occurredAt,
      stores: e.integer('storesCount'),
      users: e.integer('usersCount'),
      negotiatedPrice: e.number('oneTimePrice'),
      annualMaintenancePrice: e.number('annualMaintenancePrice'),
    );
  }

  bool _has(String? value) => value != null && value.trim().isNotEmpty;

  String? _blankToNull(String? value) => _has(value) ? value!.trim() : null;

  /// Unknown statuses map to suspended (fail closed).
  OrganizationStatus _status(String value) => switch (value) {
    'active' => OrganizationStatus.active,
    _ => OrganizationStatus.suspended,
  };
}
