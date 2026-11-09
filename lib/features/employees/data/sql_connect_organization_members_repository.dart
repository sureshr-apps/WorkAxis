import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/organization_members_remote_data_source.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/policies/organization_member_policy.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

/// Production [OrganizationMembersRepository].
///
/// Reads come from SQL Connect (server-side filters and pagination); every
/// identity write goes through the account callables. Nothing is written to
/// SQL, Auth or Firestore directly from the client.
class SqlConnectOrganizationMembersRepository
    implements OrganizationMembersRepository {
  SqlConnectOrganizationMembersRepository({
    required this._dataSource,
    required this._accounts,
  });

  final OrganizationMembersRemoteDataSource _dataSource;
  final AccountCallables _accounts;

  /// Idempotency keys for in-flight creates, so retrying the same draft
  /// reuses the `requestId` (server ledger replays instead of duplicating).
  final Map<String, String> _pendingRequestIds = {};

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
    try {
      OrganizationMemberPolicy.assertCanViewMembers(access);
      final orgId = OrganizationMemberPolicy.requireOrganizationId(access);
      final branchId = OrganizationMemberPolicy.effectiveBranchId(
        access,
        activeBranchId,
      );
      final name = query?.trim();
      if (branchId == null) {
        return await _dataSource.listByOrganization(
          organizationId: orgId,
          limit: limit,
          offset: offset,
          nameContains: name,
          status: status,
          role: role,
        );
      }
      return await _dataSource.listByBranch(
        organizationId: orgId,
        branchId: branchId,
        limit: limit,
        offset: offset,
        nameContains: name,
        status: status,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<OrganizationMember?> getMember({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  }) async {
    try {
      OrganizationMemberPolicy.assertCanViewMembers(access);
      final orgId = OrganizationMemberPolicy.requireOrganizationId(access);
      final member = await _dataSource.getById(memberId);
      if (member == null || member.organizationId != orgId) return null;
      if (access.user.role == UserRole.branchManager) {
        final branch = OrganizationMemberPolicy.effectiveBranchId(
          access,
          activeBranchId,
        );
        if (!member.branchIds.contains(branch)) return null;
      }
      return member;
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<OrganizationMember> saveMember({
    required UserAccessContext access,
    required OrganizationMember member,
    required String initialPassword,
    String? activeBranchId,
  }) async {
    try {
      return member.id.isEmpty
          ? await _create(access, member, initialPassword, activeBranchId)
          : await _update(access, member, activeBranchId);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<OrganizationMember> setMemberStatus({
    required UserAccessContext access,
    required OrganizationMember member,
    required AccountStatus status,
    String? activeBranchId,
  }) async {
    try {
      final existing = await _loadExisting(access, member.id);
      OrganizationMemberPolicy.assertCanChangeCredentialsOrStatus(
        access: access,
        existing: existing,
        activeBranchId: activeBranchId,
      );
      await _accounts.setStatus(
        targetUid: _requireUid(existing),
        status: status,
      );
      return await _reload(existing.id);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<void> resetMemberPassword({
    required UserAccessContext access,
    required OrganizationMember member,
    required String newPassword,
    String? activeBranchId,
  }) async {
    try {
      final passwordError = ContactValidators.password(newPassword);
      if (passwordError != null) throw ValidationException(passwordError);
      final existing = await _loadExisting(access, member.id);
      OrganizationMemberPolicy.assertCanChangeCredentialsOrStatus(
        access: access,
        existing: existing,
        activeBranchId: activeBranchId,
      );
      await _accounts.resetPassword(
        targetUid: _requireUid(existing),
        newPassword: newPassword,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  Future<OrganizationMember> _create(
    UserAccessContext access,
    OrganizationMember draft,
    String password,
    String? activeBranchId,
  ) async {
    final prepared = OrganizationMemberPolicy.prepareCreate(
      access: access,
      draft: draft,
      initialPassword: password,
      activeBranchId: activeBranchId,
    );
    final key = '${prepared.organizationId}|${prepared.username}';
    final requestId = _pendingRequestIds.putIfAbsent(key, RequestIds.uuidV4);
    final result = await _accounts.provision(
      requestId: requestId,
      fullName: prepared.fullName,
      username: prepared.username,
      email: prepared.email,
      phone: prepared.phone,
      password: password,
      role: prepared.role,
      organizationId: prepared.organizationId,
      branchIds: prepared.branchIds,
    );
    _pendingRequestIds.remove(key);
    return prepared.copyWith(
      id: result.memberId,
      authUid: result.uid,
      email: LoginEmail.displayable(result.loginEmail),
      status: AccountStatus.active,
    );
  }

  Future<OrganizationMember> _update(
    UserAccessContext access,
    OrganizationMember draft,
    String? activeBranchId,
  ) async {
    final existing = await _loadExisting(access, draft.id);
    final next = OrganizationMemberPolicy.prepareUpdate(
      access: access,
      existing: existing,
      draft: draft,
      activeBranchId: activeBranchId,
    );
    final uid = _requireUid(existing);

    final sameBranches =
        {...existing.branchIds}.difference({...next.branchIds}).isEmpty &&
        {...next.branchIds}.difference({...existing.branchIds}).isEmpty;
    final hadPhone = (existing.phone ?? '').isNotEmpty;
    final nextPhone = next.phone ?? '';
    await _accounts.update(
      targetUid: uid,
      fullName: next.fullName,
      email: next.email != existing.email ? next.email : null,
      clearEmail: next.email.trim().isEmpty && next.email != existing.email,
      phone: nextPhone.isNotEmpty && nextPhone != existing.phone
          ? nextPhone
          : null,
      clearPhone: hadPhone && nextPhone.isEmpty,
      role: next.role != existing.role ? next.role : null,
      branchIds: sameBranches ? null : next.branchIds,
    );
    if (draft.status != existing.status) {
      OrganizationMemberPolicy.assertCanChangeCredentialsOrStatus(
        access: access,
        existing: existing,
        activeBranchId: activeBranchId,
      );
      await _accounts.setStatus(targetUid: uid, status: draft.status);
    }
    return _reload(existing.id);
  }

  Future<OrganizationMember> _loadExisting(
    UserAccessContext access,
    String memberId,
  ) async {
    final orgId = OrganizationMemberPolicy.requireOrganizationId(access);
    final existing = await _dataSource.getById(memberId);
    if (existing == null || existing.organizationId != orgId) {
      throw const NotFoundException('Member not found in caller organization');
    }
    return existing;
  }

  Future<OrganizationMember> _reload(String id) async {
    final saved = await _dataSource.getById(id);
    if (saved == null) throw const NotFoundException('Member not found');
    return saved;
  }

  String _requireUid(OrganizationMember member) {
    final uid = member.authUid;
    if (uid == null || uid.isEmpty) {
      throw ValidationException(
        'This account has no sign-in identity yet and cannot be changed here.',
      );
    }
    return uid;
  }
}
