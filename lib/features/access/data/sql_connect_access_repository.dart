import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/features/access/data/access_remote_data_source.dart';
import 'package:workaxis/features/access/data/sql_connect_access_remote_data_source.dart';
import 'package:workaxis/features/access/domain/models/access_member_record.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/access/domain/services/access_resolver.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Production [AccessRepository].
///
/// SQL (`OrganizationMember` and `UserBranchAssignment`) is authoritative.
/// The role carried by the sign-in token is cross-checked against it, so a
/// stale or tampered token cannot widen access. Every failure denies access.
class SqlConnectAccessRepository implements AccessRepository {
  SqlConnectAccessRepository({AccessRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? SqlConnectAccessRemoteDataSource();

  final AccessRemoteDataSource _dataSource;

  @override
  Future<UserAccessContext> resolveCurrentUserAccess(AppUser user) async {
    try {
      final member = await _requireMember(user);
      final branches = await _branchesFor(user.role, member);
      return AccessResolver.resolve(
        user: user,
        organization: member.organization,
        branches: branches,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<List<BranchSummary>> getAssignedBranches(String userId) async {
    try {
      final member = await _dataSource.fetchMyMember();
      if (member == null || !_isCaller(member, userId)) return const [];
      final role = member.role;
      if (role == null || member.status != AccountStatus.active) {
        return const [];
      }
      return await _branchesFor(role, member);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<bool> validateBranchAccess({
    required String userId,
    required String branchId,
  }) async {
    try {
      final branches = await getAssignedBranches(userId);
      return branches.any((b) => b.id == branchId && b.isActive);
    } catch (_) {
      // Deny on any failure; getAssignedBranches already logged the cause.
      return false;
    }
  }

  Future<AccessMemberRecord> _requireMember(AppUser user) async {
    final member = await _dataSource.fetchMyMember();
    if (member == null) {
      throw const AccessResolutionException(
        'No membership record for the signed-in user',
        userMessage: 'Your account is not set up yet. Please contact your administrator.',
      );
    }
    if (member.role == null || member.role != user.role) {
      throw const AccessDeniedException(
        'Token role does not match the membership role',
        'Your access has changed. Please sign in again.',
      );
    }
    if (member.status != AccountStatus.active) {
      throw const AccessDeniedException(
        'Member is not active',
        'Your account is not active. Please contact your administrator.',
      );
    }
    final tokenOrg = user.organizationId;
    if (user.isCustomerLevel &&
        (member.organization == null || member.organization!.id != tokenOrg)) {
      throw const AccessDeniedException(
        'Token organization does not match the membership organization',
        'Your access has changed. Please sign in again.',
      );
    }
    return member;
  }

  Future<List<BranchSummary>> _branchesFor(
    UserRole role,
    AccessMemberRecord member,
  ) async {
    switch (role) {
      case UserRole.orgAdmin:
        final orgId = member.organization?.id;
        if (orgId == null) return const [];
        return _dataSource.fetchOrganizationBranches(orgId);
      case UserRole.branchManager:
      case UserRole.employee:
        return _dataSource.fetchMyAssignedBranches();
      case UserRole.platformOwner:
      case UserRole.platformAdmin:
        return const [];
    }
  }

  bool _isCaller(AccessMemberRecord member, String userId) =>
      member.authUid == userId || member.memberId == userId;
}
