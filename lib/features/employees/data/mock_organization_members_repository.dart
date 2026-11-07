import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/domain/models/access_user_summary.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/policies/organization_member_policy.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

class MockOrganizationMembersRepository
    implements OrganizationMembersRepository {
  MockOrganizationMembersRepository({this.accessDataSource});

  final MockAccessDataSource? accessDataSource;
  final Map<String, OrganizationMember> _members = {
    'user-bm-multi-01': const OrganizationMember(
      id: 'user-bm-multi-01',
      authUid: 'user-bm-multi-01',
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
      authUid: 'user-bm-single-01',
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
      authUid: 'user-emp-01',
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
      authUid: 'user-emp-02',
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
      authUid: 'user-emp-03',
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
      authUid: 'user-emp-04',
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

  int _nextId = 1;

  @override
  Future<PageResult<OrganizationMember>> getMembersPage({
    required UserAccessContext access,
    String? activeBranchId,
    String? query,
    AccountStatus? status,
    UserRole? role,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    OrganizationMemberPolicy.assertCanViewMembers(access);
    final orgId = OrganizationMemberPolicy.requireOrganizationId(access);
    final branchId = OrganizationMemberPolicy.effectiveBranchId(
      access,
      activeBranchId,
    );
    final normalized = query?.trim().toLowerCase() ?? '';
    final matches = _members.values.where((member) {
      if (member.organizationId != orgId) return false;
      if (branchId != null && !member.branchIds.contains(branchId)) {
        return false;
      }
      if (status != null && member.status != status) return false;
      if (role != null && member.role != role) return false;
      if (normalized.isNotEmpty &&
          !'${member.fullName} ${member.username} ${member.email} ${member.role.displayName}'
              .toLowerCase()
              .contains(normalized)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));
    final end = (offset + limit).clamp(0, matches.length);
    final start = offset.clamp(0, matches.length);
    return PageResult(
      items: List.unmodifiable(matches.sublist(start, end)),
      total: matches.length,
      offset: start,
    );
  }

  @override
  Future<OrganizationMember?> getMember({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  }) async {
    OrganizationMemberPolicy.assertCanViewMembers(access);
    final member = _members[memberId];
    if (member == null || member.organizationId != access.organization?.id) {
      return null;
    }
    if (access.user.role == UserRole.branchManager) {
      final branchId = OrganizationMemberPolicy.effectiveBranchId(
        access,
        activeBranchId,
      );
      if (!member.branchIds.contains(branchId)) return null;
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
    final isCreate = member.id.isEmpty;
    final OrganizationMember persisted;
    if (isCreate) {
      final prepared = OrganizationMemberPolicy.prepareCreate(
        access: access,
        draft: member,
        initialPassword: initialPassword,
        activeBranchId: activeBranchId,
      );
      _ensureUnique(prepared);
      final id = 'member-${_nextId++}';
      persisted = prepared.copyWith(id: id, authUid: id);
    } else {
      final existing = _requireExisting(access, member.id);
      final next = OrganizationMemberPolicy.prepareUpdate(
        access: access,
        existing: existing,
        draft: member,
        activeBranchId: activeBranchId,
      );
      _ensureUnique(next);
      var updated = next;
      if (member.status != existing.status) {
        OrganizationMemberPolicy.assertCanChangeCredentialsOrStatus(
          access: access,
          existing: existing,
          activeBranchId: activeBranchId,
        );
        updated = next.copyWith(status: member.status);
      }
      persisted = updated;
    }
    _store(persisted);
    return persisted;
  }

  @override
  Future<OrganizationMember> setMemberStatus({
    required UserAccessContext access,
    required OrganizationMember member,
    required AccountStatus status,
    String? activeBranchId,
  }) async {
    final existing = _requireExisting(access, member.id);
    OrganizationMemberPolicy.assertCanChangeCredentialsOrStatus(
      access: access,
      existing: existing,
      activeBranchId: activeBranchId,
    );
    final updated = existing.copyWith(status: status);
    _store(updated);
    return updated;
  }

  @override
  Future<void> resetMemberPassword({
    required UserAccessContext access,
    required OrganizationMember member,
    required String newPassword,
    String? activeBranchId,
  }) async {
    final existing = _requireExisting(access, member.id);
    OrganizationMemberPolicy.assertCanChangeCredentialsOrStatus(
      access: access,
      existing: existing,
      activeBranchId: activeBranchId,
    );
    final error = ContactValidators.password(newPassword);
    if (error != null) throw ValidationException(error);
    // The mock deliberately discards credentials.
  }

  OrganizationMember _requireExisting(UserAccessContext access, String id) {
    final orgId = OrganizationMemberPolicy.requireOrganizationId(access);
    final existing = _members[id];
    if (existing == null || existing.organizationId != orgId) {
      throw const NotFoundException('Member not found in caller organization');
    }
    return existing;
  }

  void _ensureUnique(OrganizationMember candidate) {
    final phone = candidate.phone ?? '';
    final duplicate = _members.values.any((existing) {
      if (existing.id == candidate.id) return false;
      return existing.username.toLowerCase() == candidate.username ||
          (candidate.email.isNotEmpty &&
              existing.email.toLowerCase() == candidate.email) ||
          (phone.isNotEmpty &&
              ContactValidators.normalizePhone(existing.phone) == phone);
    });
    if (duplicate) {
      throw ValidationException(
        'Another organization account already uses that username, email, or phone.',
      );
    }
  }

  void _store(OrganizationMember member) {
    _members[member.id] = member;
    accessDataSource?.saveUserAccessProfile(
      AccessUserSummary(
        id: member.id,
        organizationId: member.organizationId,
        fullName: member.fullName,
        role: member.role,
      ),
    );
    accessDataSource?.setAssignedBranchIds(member.id, member.branchIds);
  }
}
