import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/platform_organizations/data/platform_organizations_remote_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/license_event_parser.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';

/// [PlatformOrganizationsRemoteDataSource] backed by Firebase SQL Connect.
class SqlConnectPlatformOrganizationsRemoteDataSource
    implements PlatformOrganizationsRemoteDataSource {
  SqlConnectPlatformOrganizationsRemoteDataSource({
    WorkaxisConnectorConnector? connector,
  }) : _customConnector = connector;

  final WorkaxisConnectorConnector? _customConnector;
  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<PageResult<CustomerOrganization>> listPage({
    required int limit,
    required int offset,
    String? nameContains,
    OrganizationStatus? status,
  }) async {
    var builder = _connector.listOrganizationsPaged(
      limit: limit,
      offset: offset,
    );
    if (nameContains != null && nameContains.trim().isNotEmpty) {
      builder = builder.nameContains(nameContains.trim());
    }
    if (status != null) builder = builder.status(status.name);
    final data = (await builder.execute()).data;
    return PageResult(
      items: [
        for (final o in data.organizations)
          CustomerOrganization(
            id: o.id,
            name: o.name,
            code: o.code,
            status: _status(o.status),
            // Counts are fetched on the detail page, not for every list row.
            branchCount: 0,
            employeeCount: 0,
            createdAt: o.createdAt.toDateTime(),
            category: _blankToNull(o.category),
          ),
      ],
      total: data.total.firstOrNull?.count_ ?? 0,
      offset: offset,
    );
  }

  @override
  Future<OrganizationStatusCounts> statusCounts() async {
    final data = (await _connector.getPlatformStats().execute()).data;
    var active = 0;
    var suspended = 0;
    for (final row in data.organizationsByStatus) {
      if (row.status == 'active') active += row.count_;
      if (row.status == 'suspended') suspended += row.count_;
    }
    return OrganizationStatusCounts(active: active, suspended: suspended);
  }

  @override
  Future<CustomerOrganization?> getById(String id) async {
    final (org, stats, admins) = await (
      _connector.getOrganizationById(id: id).execute(),
      _connector.getOrganizationStats(orgId: id).execute(),
      _connector
          .listMembersByOrgPaged(orgId: id, limit: 50, offset: 0)
          .role('orgAdmin')
          .execute(),
    ).wait;
    final o = org.data.organization;
    if (o == null) return null;
    return CustomerOrganization(
      id: o.id,
      name: o.name,
      code: o.code,
      status: _status(o.status),
      branchCount: stats.data.branchCount.firstOrNull?.count_ ?? 0,
      employeeCount: stats.data.memberCount.firstOrNull?.count_ ?? 0,
      createdAt: o.createdAt.toDateTime(),
      description: _blankToNull(o.description),
      category: _blankToNull(o.category),
      contactName: _blankToNull(o.contactName),
      contactEmail: _blankToNull(o.contactEmail),
      contactPhone: _blankToNull(o.contactPhone),
      address: _blankToNull(o.address),
      taxIdentification: _blankToNull(o.taxIdentification),
      admins: [
        for (final m in admins.data.organizationMembers)
          OrganizationAdminUser(
            id: m.id,
            name: m.fullName,
            email: LoginEmail.displayable(m.email),
            phone: m.phone ?? '',
            username: m.username,
            authUid: m.authUid,
            status: OrganizationAdminStatus.fromAccountName(m.status),
          ),
      ],
    );
  }

  @override
  Future<OrganizationLicenseDetails?> getLicense(String organizationId) async {
    final (agreements, events, org) = await (
      _connector.getCommercialAgreementByOrg(orgId: organizationId).execute(),
      _connector.listLicenseEventsByOrg(orgId: organizationId).execute(),
      _connector.getOrganizationById(id: organizationId).execute(),
    ).wait;
    final agreement = agreements.data.commercialAgreements.firstOrNull;
    if (agreement == null) return null;

    final history = [
      for (final e in events.data.licenseEvents) _historyEntry(e),
    ];
    return OrganizationLicenseDetails(
      planName: agreement.planName,
      status: agreement.status,
      level: LicenseEventParser.level(agreement.planTier) ?? 1,
      agreementId: agreement.agreementReference,
      agreementStart: agreement.startDate,
      agreementExpiry: agreement.expiryDate,
      maximumStores: agreement.maxStores,
      maximumUsers: agreement.maxUsers,
      negotiatedPrice: agreement.negotiatedPrice,
      annualMaintenancePrice: agreement.annualMaintenancePrice,
      currencyCode: org.data.organization?.currency ?? 'INR',
      history: history,
    );
  }

  @override
  Future<String> create(
    CreateOrganizationRequest request, {
    required String code,
  }) async {
    final builder = _connector
        .createOrganization(name: request.name.trim(), code: code)
        .country('India')
        .currency('INR')
        .status('active');
    // Unset optional variables are omitted, never sent as null.
    if (_has(request.category)) builder.category(request.category!.trim());
    if (_has(request.description)) {
      builder.description(request.description!.trim());
    }
    if (_has(request.taxIdentification)) {
      builder.taxIdentification(request.taxIdentification!.trim());
    }
    if (_has(request.contactName)) {
      builder.contactName(request.contactName!.trim());
    }
    if (_has(request.contactEmail)) {
      builder.contactEmail(request.contactEmail!.trim());
    }
    if (_has(request.contactPhone)) {
      builder.contactPhone(request.contactPhone!.trim());
    }
    if (_has(request.address)) builder.address(request.address!.trim());
    final result = await builder.execute();
    return result.data.organization_insert.id;
  }

  /// Writes every editable field; a blank value stores an empty string so the
  /// field can be cleared (reads map blank back to null).
  @override
  Future<void> update(CustomerOrganization organization) async {
    await _connector
        .updateOrganization(id: organization.id)
        .name(organization.name.trim())
        .category((organization.category ?? '').trim())
        .description((organization.description ?? '').trim())
        .taxIdentification((organization.taxIdentification ?? '').trim())
        .contactName((organization.contactName ?? '').trim())
        .contactEmail((organization.contactEmail ?? '').trim())
        .contactPhone((organization.contactPhone ?? '').trim())
        .address((organization.address ?? '').trim())
        .execute();
  }

  LicenseHistoryEntry _historyEntry(ListLicenseEventsByOrgLicenseEvents e) {
    final occurredAt = e.createdAt.toDateTime();
    final period = LicenseEventParser.period(e.validityPeriod);
    return LicenseHistoryEntry(
      event: e.eventType,
      occurredAt: occurredAt,
      planName: e.planName,
      level: LicenseEventParser.level(e.planTier) ?? 1,
      periodStart: period?.start ?? occurredAt,
      periodEnd: period?.end ?? occurredAt,
      stores: e.storesCount,
      users: e.usersCount,
      negotiatedPrice: e.oneTimePrice,
      annualMaintenancePrice: e.annualMaintenancePrice,
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
