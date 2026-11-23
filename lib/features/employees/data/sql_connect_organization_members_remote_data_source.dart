import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/organization_members_remote_data_source.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// [OrganizationMembersRemoteDataSource] backed by the data gateway
/// (`ListMembersByOrgPaged`, `ListMembersByBranchPaged`, `GetMemberById`).
class SqlConnectOrganizationMembersRemoteDataSource
    implements OrganizationMembersRemoteDataSource {
  SqlConnectOrganizationMembersRemoteDataSource({required this._gateway});

  final DataGateway _gateway;

  @override
  Future<PageResult<OrganizationMember>> listByOrganization({
    required String organizationId,
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
    UserRole? role,
  }) async {
    final data = await _gateway.call('ListMembersByOrgPaged', {
      'orgId': organizationId,
      'limit': limit,
      'offset': offset,
      // Unset optional variables are omitted, never sent as null.
      if (nameContains != null && nameContains.isNotEmpty)
        'nameContains': nameContains,
      'status': ?status?.name,
      'role': ?role?.name,
    });
    return PageResult(
      items: [
        for (final m in data.objects('organizationMembers'))
          _build(m, organizationId: organizationId),
      ],
      total: data.countOf('total'),
      offset: offset,
    );
  }

  @override
  Future<PageResult<OrganizationMember>> listByBranch({
    required String organizationId,
    required String branchId,
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
    UserRole? role,
  }) async {
    final data = await _gateway.call('ListMembersByBranchPaged', {
      'branchId': branchId,
      'limit': limit,
      'offset': offset,
      if (nameContains != null && nameContains.isNotEmpty)
        'nameContains': nameContains,
      'status': ?status?.name,
      'role': ?role?.name,
    });
    return PageResult(
      items: [
        for (final a in data.objects('userBranchAssignments'))
          _build(a.object('member'), organizationId: organizationId),
      ],
      total: data.countOf('total'),
      offset: offset,
    );
  }

  @override
  Future<OrganizationMember?> getById(String memberId) async {
    final data = await _gateway.call('GetMemberById', {'id': memberId});
    final m = data.optObject('organizationMember');
    if (m == null) return null;
    return _build(
      m,
      organizationId: m.optObject('organization')?.string('id') ?? '',
    );
  }

  /// Unknown roles map to the least-privileged role and unknown statuses to
  /// suspended, so malformed data can never widen access.
  OrganizationMember _build(
    Map<String, dynamic> m, {
    required String organizationId,
  }) {
    final role = m.string('role');
    final status = m.string('status');
    final assignments =
        m.optObjects('userBranchAssignments_on_member') ??
        const <Map<String, dynamic>>[];
    final branchNamesById = <String, String>{};
    for (final assignment in assignments) {
      final branch = assignment.object('branch');
      final name = branch.optString('name');
      if (name != null && name.trim().isNotEmpty) {
        branchNamesById[branch.string('id')] = name;
      }
    }
    return OrganizationMember(
      id: m.string('id'),
      authUid: m.optString('authUid'),
      organizationId: organizationId,
      fullName: m.string('fullName'),
      username: m.string('username'),
      email: LoginEmail.displayable(m.string('email')),
      phone: m.optString('phone'),
      employeeCode: m.optString('employeeCode'),
      role:
          UserRole.values.where((r) => r.name == role).firstOrNull ??
          UserRole.employee,
      branchIds: List.unmodifiable([
        for (final assignment in assignments)
          assignment.object('branch').string('id'),
      ]),
      branchNamesById: Map.unmodifiable(branchNamesById),
      status:
          AccountStatus.values.where((s) => s.name == status).firstOrNull ??
          AccountStatus.suspended,
    );
  }
}
