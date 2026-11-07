import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/data/platform_organizations_remote_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';

/// In-memory [PlatformOrganizationsRemoteDataSource] seeded with the mock
/// organizations. Behaves like the SQL source: server-assigned ids, server
/// side filters/pagination and no status writes through [update].
class FakeOrganizationsDataSource
    implements PlatformOrganizationsRemoteDataSource {
  FakeOrganizationsDataSource() {
    final seed = MockPlatformOrganizationsDataSource();
    for (final org in seed.getOrganizations()) {
      // Seeded admins get sign-in identities, as server records always do.
      _orgs[org.id] = org.copyWith(
        admins: [
          for (final a in org.admins) a.copyWith(authUid: 'uid-${a.id}'),
        ],
      );
      _licenses[org.id] = seed.getLicenseDetails(org.id);
    }
  }

  final Map<String, CustomerOrganization> _orgs = {};
  final Map<String, OrganizationLicenseDetails?> _licenses = {};
  int _next = 1;
  final List<CustomerOrganization> updates = [];

  /// Used by the status callable fake.
  void setStatus(String id, OrganizationStatus status) {
    _orgs[id] = _orgs[id]!.copyWith(status: status);
  }

  bool contains(String id) => _orgs.containsKey(id);

  @override
  Future<PageResult<CustomerOrganization>> listPage({
    required int limit,
    required int offset,
    String? nameContains,
    OrganizationStatus? status,
  }) async {
    final rows = _orgs.values.where((o) {
      if (status != null && o.status != status) return false;
      return nameContains == null ||
          nameContains.isEmpty ||
          o.name.toLowerCase().contains(nameContains.toLowerCase());
    }).toList();
    final start = offset.clamp(0, rows.length);
    final end = (offset + limit).clamp(0, rows.length);
    return PageResult(
      items: rows.sublist(start, end),
      total: rows.length,
      offset: start,
    );
  }

  @override
  Future<OrganizationStatusCounts> statusCounts() async {
    final all = _orgs.values;
    return OrganizationStatusCounts(
      active: all.where((o) => o.status.isActive).length,
      suspended: all.where((o) => o.status.isSuspended).length,
    );
  }

  @override
  Future<CustomerOrganization?> getById(String id) async => _orgs[id];

  @override
  Future<OrganizationLicenseDetails?> getLicense(String organizationId) async =>
      _licenses[organizationId];

  @override
  Future<String> create(
    CreateOrganizationRequest request, {
    required String code,
  }) async {
    final id = 'srv-org-${_next++}';
    String? blank(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    _orgs[id] = CustomerOrganization(
      id: id,
      name: request.name.trim(),
      code: code,
      status: OrganizationStatus.active,
      branchCount: 0,
      employeeCount: 0,
      createdAt: DateTime.utc(2026, 1, 1),
      description: blank(request.description),
      category: blank(request.category),
      contactName: blank(request.contactName),
      contactEmail: blank(request.contactEmail),
      contactPhone: blank(request.contactPhone),
      address: blank(request.address),
      taxIdentification: blank(request.taxIdentification),
    );
    return id;
  }

  @override
  Future<void> update(CustomerOrganization organization) async {
    updates.add(organization);
    final existing = _orgs[organization.id]!;
    // Status is not writable here, exactly like UpdateOrganization.
    _orgs[organization.id] = organization.copyWith(
      status: existing.status,
      branchCount: existing.branchCount,
      employeeCount: existing.employeeCount,
      createdAt: existing.createdAt,
    );
  }

  int _nextAdmin = 1;

  /// What `provisionUser` does to the member table.
  String addAdmin(
    String organizationId, {
    required String name,
    required String username,
    String email = '',
    String phone = '',
  }) {
    final id = 'srv-admin-${_nextAdmin++}';
    final org = _orgs[organizationId]!;
    _orgs[organizationId] = org.copyWith(
      admins: [
        ...org.admins,
        OrganizationAdminUser(
          id: id,
          authUid: 'uid-$id',
          name: name,
          username: username,
          email: email,
          phone: phone,
        ),
      ],
    );
    return id;
  }

  /// What `updateUserAccount` / `setUserStatus` do to a member row.
  void changeAdmin(
    String authUid, {
    String? name,
    String? email,
    String? phone,
    OrganizationAdminStatus? status,
  }) {
    for (final entry in _orgs.entries.toList()) {
      final admins = entry.value.admins;
      if (!admins.any((a) => a.authUid == authUid)) continue;
      _orgs[entry.key] = entry.value.copyWith(
        admins: [
          for (final a in admins)
            if (a.authUid != authUid)
              a
            else
              OrganizationAdminUser(
                id: a.id,
                authUid: a.authUid,
                name: name ?? a.name,
                username: a.username,
                email: email ?? a.email,
                phone: phone ?? a.phone,
                roleTitle: a.roleTitle,
                status: status ?? a.status,
                lastLogin: a.lastLogin,
              ),
        ],
      );
    }
  }

  /// A member row that has not been linked to a Firebase Auth user yet.
  void addAdminWithoutIdentity(String organizationId) {
    final org = _orgs[organizationId]!;
    _orgs[organizationId] = org.copyWith(
      admins: [
        ...org.admins,
        const OrganizationAdminUser(
          id: 'orphan',
          name: 'Orphan Admin',
          username: 'orphan',
          email: '',
          phone: '',
        ),
      ],
    );
  }
}
