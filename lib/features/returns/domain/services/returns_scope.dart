import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

/// What a user may read: their own returns, or the returns of [branches].
class ReturnsReadScope {
  const ReturnsReadScope.own() : ownOnly = true, branches = const [];
  const ReturnsReadScope.branches(this.branches) : ownOnly = false;

  final bool ownOnly;
  final List<BranchSummary> branches;
}

/// Authorization rules for returns, shared by the mock and real repositories
/// so both enforce the same scoping. The server remains authoritative.
class ReturnsScope {
  const ReturnsScope();

  ReturnsReadScope forRead(UserAccessContext access, String? activeBranchId) {
    _requireOrganization(access);
    switch (access.user.role) {
      case UserRole.employee:
        return const ReturnsReadScope.own();
      case UserRole.branchManager:
        final branchId = activeBranchId ?? access.activeBranch?.branchId;
        if (branchId == null) {
          throw const BranchAuthorizationException(
            'Branch Manager has no active branch.',
            userMessage: 'Select a branch to view its returns.',
          );
        }
        return ReturnsReadScope.branches([_assigned(access, branchId)]);
      case UserRole.orgAdmin:
        if (activeBranchId != null) {
          return ReturnsReadScope.branches([_assigned(access, activeBranchId)]);
        }
        return ReturnsReadScope.branches(access.assignedBranches);
      case UserRole.platformOwner:
      case UserRole.platformAdmin:
        throw const AccessDeniedException(
          'Platform users have no returns scope.',
        );
    }
  }

  /// Branch a new return is filed against: the requested, active or only
  /// assigned active branch. Employees and Branch Managers only.
  BranchSummary forSubmit(UserAccessContext access, String? branchId) {
    _requireOrganization(access);
    final role = access.user.role;
    if (role != UserRole.employee && role != UserRole.branchManager) {
      throw const AccessDeniedException(
        'Only employees and branch managers submit returns.',
      );
    }
    final id =
        branchId ??
        access.activeBranch?.branchId ??
        (access.activeAssignedBranches.length == 1
            ? access.activeAssignedBranches.single.id
            : null);
    if (id == null) {
      throw const BranchAuthorizationException(
        'No branch selected for the return.',
        userMessage: 'Select a branch before submitting a return.',
      );
    }
    final branch = _assigned(access, id);
    if (!branch.isActive) {
      throw const BranchAuthorizationException('Branch is not active.');
    }
    return branch;
  }

  /// Validates that [access] may review [item]; returns its branch.
  BranchSummary forReview(
    UserAccessContext access,
    String? activeBranchId,
    ReturnItem item,
  ) {
    final orgId = _requireOrganization(access);
    final role = access.user.role;
    if (role != UserRole.orgAdmin && role != UserRole.branchManager) {
      throw const AccessDeniedException(
        'Only managers may review return requests.',
      );
    }
    if (item.organizationId != orgId) {
      throw const AccessDeniedException(
        'Return belongs to another organization.',
      );
    }
    if (role == UserRole.branchManager) {
      final active = activeBranchId ?? access.activeBranch?.branchId;
      if (active == null || active != item.branchId) {
        throw const BranchAuthorizationException(
          'Return is outside the active branch.',
          userMessage: 'This return belongs to a different branch.',
        );
      }
    }
    return _assigned(access, item.branchId);
  }

  String _requireOrganization(UserAccessContext access) {
    final orgId = access.organization?.id;
    if (orgId == null || orgId.isEmpty) {
      throw const AccessDeniedException('No organization context.');
    }
    return orgId;
  }

  BranchSummary _assigned(UserAccessContext access, String branchId) {
    final branch = access.assignedBranches
        .where((b) => b.id == branchId)
        .firstOrNull;
    if (branch == null) {
      throw const BranchAuthorizationException(
        'Branch is outside the assigned set.',
      );
    }
    return branch;
  }
}
