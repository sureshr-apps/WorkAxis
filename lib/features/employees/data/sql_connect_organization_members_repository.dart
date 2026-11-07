import 'dart:math';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

/// Production implementation of [OrganizationMembersRepository] using Firebase SQL Connect.
class SqlConnectOrganizationMembersRepository implements OrganizationMembersRepository {
  SqlConnectOrganizationMembersRepository({
    WorkaxisConnectorConnector? connector,
  }) : _customConnector = connector;

  final WorkaxisConnectorConnector? _customConnector;
  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  final Random _random = Random();

  String _getOrgId(UserAccessContext access) {
    final orgId = access.organization?.id;
    if (orgId == null || orgId.isEmpty) {
      throw const AccessDeniedException('No organization context available.');
    }
    return orgId;
  }

  @override
  Future<List<OrganizationMember>> getMembers({
    required UserAccessContext access,
    String? activeBranchId,
    String? query,
  }) async {
    final orgId = _getOrgId(access);
    try {
      final response = await _connector.listMembersByOrg(orgId: orgId).execute();
      var members = response.data.organizationMembers
          .map((m) => _toMember(orgId, m))
          .toList();

      // Enforce role-based access scoping
      if (access.user.role == UserRole.employee) {
        members = members.where((m) => m.id == access.user.id).toList();
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        members = members.where((m) =>
            m.fullName.toLowerCase().contains(q) ||
            m.email.toLowerCase().contains(q) ||
            m.username.toLowerCase().contains(q)).toList();
      }

      return members;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to retrieve members: ${e.toString()}');
    }
  }

  @override
  Future<OrganizationMember?> getMember({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  }) async {
    final members = await getMembers(
      access: access,
      activeBranchId: activeBranchId,
    );
    return members.where((m) => m.id == memberId).firstOrNull;
  }

  @override
  Future<OrganizationMember> saveMember({
    required UserAccessContext access,
    required OrganizationMember member,
    required String initialPassword,
    String? activeBranchId,
  }) async {
    final orgId = _getOrgId(access);

    if (access.user.role == UserRole.branchManager) {
      if (member.role != UserRole.employee) {
        throw const AccessDeniedException('Branch Managers may only create Employees.');
      }
    }

    final id = member.id.isEmpty ? 'usr-${_random.nextInt(90000) + 10000}' : member.id;

    try {
      await _connector
          .createOrganizationMember(
            id: id,
            orgId: orgId,
            fullName: member.fullName,
            username: member.username,
            email: member.email,
            role: member.role.name,
          )
          .phone(member.phone)
          .status(member.status.name)
          .execute();

      return member.copyWith(fullName: member.fullName);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to save organization member: ${e.toString()}');
    }
  }

  OrganizationMember _toMember(
    String orgId,
    ListMembersByOrgOrganizationMembers m,
  ) {
    final role = UserRole.values.firstWhere(
      (r) => r.name.toLowerCase() == m.role.toLowerCase(),
      orElse: () => UserRole.employee,
    );
    final status = AccountStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == m.status.toLowerCase(),
      orElse: () => AccountStatus.active,
    );

    return OrganizationMember(
      id: m.id,
      organizationId: orgId,
      fullName: m.fullName,
      username: m.username,
      email: m.email,
      phone: m.phone,
      role: role,
      branchIds: const [],
      status: status,
    );
  }
}
