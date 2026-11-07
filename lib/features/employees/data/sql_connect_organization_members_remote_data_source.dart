import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/organization_members_remote_data_source.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// [OrganizationMembersRemoteDataSource] backed by Firebase SQL Connect.
class SqlConnectOrganizationMembersRemoteDataSource
    implements OrganizationMembersRemoteDataSource {
  SqlConnectOrganizationMembersRemoteDataSource({
    WorkaxisConnectorConnector? connector,
  }) : _customConnector = connector;

  final WorkaxisConnectorConnector? _customConnector;
  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<PageResult<OrganizationMember>> listByOrganization({
    required String organizationId,
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
    UserRole? role,
  }) async {
    var builder = _connector.listMembersByOrgPaged(
      orgId: organizationId,
      limit: limit,
      offset: offset,
    );
    if (nameContains != null && nameContains.isNotEmpty) {
      builder = builder.nameContains(nameContains);
    }
    if (status != null) builder = builder.status(status.name);
    if (role != null) builder = builder.role(role.name);
    final data = (await builder.execute()).data;
    return PageResult(
      items: [
        for (final m in data.organizationMembers)
          _build(
            id: m.id,
            authUid: m.authUid,
            organizationId: organizationId,
            fullName: m.fullName,
            username: m.username,
            email: m.email,
            phone: m.phone,
            role: m.role,
            status: m.status,
            branchIds: m.userBranchAssignments_on_member
                .map((a) => a.branch.id)
                .toList(),
          ),
      ],
      total: data.total.firstOrNull?.count_ ?? 0,
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
  }) async {
    var builder = _connector.listMembersByBranchPaged(
      branchId: branchId,
      limit: limit,
      offset: offset,
    );
    if (nameContains != null && nameContains.isNotEmpty) {
      builder = builder.nameContains(nameContains);
    }
    if (status != null) builder = builder.status(status.name);
    final data = (await builder.execute()).data;
    return PageResult(
      items: [
        for (final a in data.userBranchAssignments)
          _build(
            id: a.member.id,
            authUid: a.member.authUid,
            organizationId: organizationId,
            fullName: a.member.fullName,
            username: a.member.username,
            email: a.member.email,
            phone: a.member.phone,
            role: a.member.role,
            status: a.member.status,
            branchIds: a.member.userBranchAssignments_on_member
                .map((x) => x.branch.id)
                .toList(),
          ),
      ],
      total: data.total.firstOrNull?.count_ ?? 0,
      offset: offset,
    );
  }

  @override
  Future<OrganizationMember?> getById(String memberId) async {
    final data = (await _connector.getMemberById(id: memberId).execute()).data;
    final m = data.organizationMember;
    if (m == null) return null;
    return _build(
      id: m.id,
      authUid: m.authUid,
      organizationId: m.organization?.id ?? '',
      fullName: m.fullName,
      username: m.username,
      email: m.email,
      phone: m.phone,
      role: m.role,
      status: m.status,
      branchIds: m.userBranchAssignments_on_member
          .map((a) => a.branch.id)
          .toList(),
    );
  }

  /// Unknown roles map to the least-privileged role and unknown statuses to
  /// suspended, so malformed data can never widen access.
  OrganizationMember _build({
    required String id,
    required String? authUid,
    required String organizationId,
    required String fullName,
    required String username,
    required String email,
    required String? phone,
    required String role,
    required String status,
    required List<String> branchIds,
  }) {
    return OrganizationMember(
      id: id,
      authUid: authUid,
      organizationId: organizationId,
      fullName: fullName,
      username: username,
      email: LoginEmail.displayable(email),
      phone: phone,
      role:
          UserRole.values.where((r) => r.name == role).firstOrNull ??
          UserRole.employee,
      branchIds: List.unmodifiable(branchIds),
      status:
          AccountStatus.values.where((s) => s.name == status).firstOrNull ??
          AccountStatus.suspended,
    );
  }
}
