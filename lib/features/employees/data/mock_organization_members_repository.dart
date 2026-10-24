import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/domain/models/access_user_summary.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

class MockOrganizationMembersRepository
    implements OrganizationMembersRepository {
  MockOrganizationMembersRepository({this.accessDataSource});

  final MockAccessDataSource? accessDataSource;
  final Map<String, OrganizationMember> _members = {
    'user-bm-multi-01': const OrganizationMember(
      id: 'user-bm-multi-01',
      organizationId: 'org-acme',
      fullName: 'Marcus Chen',
      username: 'marcus.chen',
      email: 'marcus.chen@example.com',
      role: UserRole.branchManager,
      branchIds: ['br-01', 'br-02', 'br-03'],
      status: AccountStatus.active,
    ),
    'user-bm-single-01': const OrganizationMember(
      id: 'user-bm-single-01',
      organizationId: 'org-acme',
      fullName: 'Sophia Patel',
      username: 'sophia.patel',
      email: 'sophia.patel@example.com',
      role: UserRole.branchManager,
      branchIds: ['br-04'],
      status: AccountStatus.active,
    ),
    'user-emp-01': const OrganizationMember(
      id: 'user-emp-01',
      organizationId: 'org-acme',
      fullName: 'Sarah Connor',
      username: 'sarah.connor',
      email: 'sarah.connor@example.com',
      phone: '+1 212 555 0114',
      role: UserRole.employee,
      branchIds: ['br-01'],
      status: AccountStatus.active,
    ),
    'user-emp-02': const OrganizationMember(
      id: 'user-emp-02',
      organizationId: 'org-acme',
      fullName: 'Alex Chen',
      username: 'alex.chen',
      email: 'alex.chen@example.com',
      phone: '+1 212 555 0182',
      role: UserRole.employee,
      branchIds: ['br-01'],
      status: AccountStatus.active,
    ),
    'user-emp-03': const OrganizationMember(
      id: 'user-emp-03',
      organizationId: 'org-acme',
      fullName: 'Priya Shah',
      username: 'priya.shah',
      email: 'priya.shah@example.com',
      phone: '+1 212 555 0148',
      role: UserRole.employee,
      branchIds: ['br-02'],
      status: AccountStatus.active,
    ),
    'user-emp-04': const OrganizationMember(
      id: 'user-emp-04',
      organizationId: 'org-acme',
      fullName: 'Daniel Kim',
      username: 'daniel.kim',
      email: 'daniel.kim@example.com',
      phone: '+1 212 555 0193',
      role: UserRole.employee,
      branchIds: ['br-04'],
      status: AccountStatus.suspended,
    ),
  };

  @override
  Future<List<OrganizationMember>> getMembers({
    required UserAccessContext access,
    String? activeBranchId,
    String? query,
  }) async {
    final orgId = access.organization?.id;
    if (orgId == null) {
      return const [];
    }
    final branchId = _effectiveBranchId(access, activeBranchId);
    final normalized = query?.trim().toLowerCase() ?? '';
    return _members.values
        .where((member) {
          if (member.organizationId != orgId) {
            return false;
          }
          if (access.user.role == UserRole.employee &&
              member.id != access.user.id) {
            return false;
          }
          if (access.user.role == UserRole.branchManager &&
              member.role != UserRole.employee) {
            return false;
          }
          if (branchId != null && !member.branchIds.contains(branchId)) {
            return false;
          }
          if (normalized.isNotEmpty &&
              !'${member.fullName} ${member.username} ${member.email} ${member.role.displayName}'
                  .toLowerCase()
                  .contains(normalized)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  @override
  Future<OrganizationMember?> getMember({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  }) async {
    final member = _members[memberId];
    if (member == null || member.organizationId != access.organization?.id) {
      return null;
    }
    if (access.user.role == UserRole.employee && member.id != access.user.id) {
      return null;
    }
    if (access.user.role == UserRole.branchManager &&
        member.role != UserRole.employee) {
      return null;
    }
    final branchId = _effectiveBranchId(access, activeBranchId);
    if (branchId != null && !member.branchIds.contains(branchId)) {
      return null;
    }
    return member;
  }

  @override
  Future<OrganizationMember> saveMember({
    required UserAccessContext access,
    required OrganizationMember member,
    required String initialPassword,
    String? activeBranchId,
  }) async {
    final actorRole = access.user.role;
    final orgId = access.organization?.id;
    if (orgId == null || member.organizationId != orgId) {
      throw StateError('This account is outside your organization.');
    }
    if (member.fullName.trim().isEmpty ||
        member.username.trim().isEmpty ||
        !member.email.contains('@')) {
      throw StateError('Enter a name, username, and valid email address.');
    }
    if (actorRole != UserRole.orgAdmin && actorRole != UserRole.branchManager) {
      throw StateError(
        'You do not have permission to manage organization accounts.',
      );
    }
    final branchId = _effectiveBranchId(access, activeBranchId);
    if (actorRole == UserRole.branchManager) {
      final existingMember = _members[member.id];
      if (existingMember != null && existingMember.role != UserRole.employee) {
        throw StateError('Branch managers can only edit employee accounts.');
      }
      if (existingMember != null &&
          (branchId == null || !existingMember.branchIds.contains(branchId))) {
        throw StateError(
          'Branch managers can only edit employees assigned to their active branch.',
        );
      }
      if (branchId == null ||
          member.role != UserRole.employee ||
          member.branchIds.length != 1 ||
          member.branchIds.single != branchId) {
        throw StateError(
          'Branch managers can only manage employees in their active branch.',
        );
      }
    } else if (member.role.isPlatformLevel) {
      throw StateError(
        'Platform accounts cannot be created in an organization.',
      );
    }
    if (member.branchIds.isEmpty ||
        member.branchIds.any(
          (id) => !access.assignedBranches.any((branch) => branch.id == id),
        )) {
      throw StateError('Select a branch within your authorized organization.');
    }
    final normalizedUsername = member.username.trim().toLowerCase();
    final normalizedEmail = member.email.trim().toLowerCase();
    final normalizedPhone = member.phone?.replaceAll(RegExp(r'\D'), '');
    final duplicate = _members.values.any((existing) {
      if (existing.id == member.id) return false;
      return existing.username.toLowerCase() == normalizedUsername ||
          existing.email.toLowerCase() == normalizedEmail ||
          (normalizedPhone != null &&
              normalizedPhone.isNotEmpty &&
              existing.phone?.replaceAll(RegExp(r'\D'), '') == normalizedPhone);
    });
    if (duplicate) {
      throw StateError(
        'Another organization account already uses that username, email, or phone.',
      );
    }

    // The mock repository deliberately discards credentials. A real adapter
    // will pass this value directly to Firebase Authentication.
    if (member.id.isEmpty && initialPassword.length < 8) {
      throw StateError('Set an initial password of at least 8 characters.');
    }
    final saved = member;
    final persisted = OrganizationMember(
      id: member.id.isEmpty
          ? 'member-${DateTime.now().microsecondsSinceEpoch}'
          : saved.id,
      organizationId: saved.organizationId,
      fullName: saved.fullName.trim(),
      username: saved.username.trim(),
      email: saved.email.trim(),
      phone: saved.phone,
      role: saved.role,
      branchIds: List.unmodifiable(saved.branchIds),
      status: saved.status,
    );
    _members[persisted.id] = persisted;
    accessDataSource?.saveUserAccessProfile(
      AccessUserSummary(
        id: persisted.id,
        organizationId: persisted.organizationId,
        fullName: persisted.fullName,
        role: persisted.role,
      ),
    );
    accessDataSource?.setAssignedBranchIds(persisted.id, persisted.branchIds);
    return persisted;
  }

  String? _effectiveBranchId(UserAccessContext access, String? requested) {
    if (access.user.role != UserRole.branchManager) return requested;
    if (requested == null ||
        !access.assignedBranches.any(
          (branch) => branch.id == requested && branch.isActive,
        )) {
      throw StateError('Choose an active branch assigned to your account.');
    }
    return requested;
  }
}
