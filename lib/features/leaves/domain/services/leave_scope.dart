import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

/// An authorized read of one [LeaveQueue]. [branch] is the active branch for
/// [LeaveQueue.branchEmployees] and null otherwise.
class LeaveReadScope {
  const LeaveReadScope(this.queue, {this.branch});

  final LeaveQueue queue;
  final BranchSummary? branch;
}

/// Shared client-side scope checks for the mock and SQL repositories.
/// The server repeats each authorization check using its SQL-resolved actor.
class LeaveScope {
  const LeaveScope();

  LeaveReadScope forRead(
    UserAccessContext access,
    String? activeBranchId,
    LeaveQueue queue,
  ) {
    _requireOrganization(access);
    final role = access.user.role;
    if (role == UserRole.platformOwner || role == UserRole.platformAdmin) {
      throw const AccessDeniedException(
        'Platform users do not have customer leave scope.',
      );
    }
    if (!queue.isAvailableTo(role)) {
      throw AccessDeniedException(
        'Role ${role.name} cannot read the ${queue.name} leave queue.',
      );
    }
    if (queue != LeaveQueue.branchEmployees) return LeaveReadScope(queue);
    final id = activeBranchId ?? access.activeBranch?.branchId;
    if (id == null) {
      throw const BranchAuthorizationException(
        'Branch Manager has no active branch.',
        userMessage: 'Select a branch to review leave requests.',
      );
    }
    return LeaveReadScope(queue, branch: _assigned(access, id));
  }

  /// Any customer member of the organization (leave types are shared).
  void assertMember(UserAccessContext access) {
    _requireOrganization(access);
    if (access.user.role.isPlatformLevel) {
      throw const AccessDeniedException(
        'Platform users do not have customer leave scope.',
      );
    }
  }

  /// An Employee or Branch Manager acting on their own leave (e.g. a draft
  /// preview, which needs no branch).
  void assertApplicant(UserAccessContext access) {
    _requireOrganization(access);
    final role = access.user.role;
    if (role != UserRole.employee && role != UserRole.branchManager) {
      throw const AccessDeniedException(
        'Only employees and Branch Managers may apply for leave.',
      );
    }
  }

  BranchSummary forSubmit(
    UserAccessContext access, {
    String? branchId,
    String? activeBranchId,
  }) {
    assertApplicant(access);
    final role = access.user.role;
    final contextBranch = activeBranchId ?? access.activeBranch?.branchId;
    final id = role == UserRole.branchManager
        ? contextBranch
        : branchId ??
              contextBranch ??
              (access.activeAssignedBranches.length == 1
                  ? access.activeAssignedBranches.single.id
                  : null);
    if (id == null) {
      throw const BranchAuthorizationException(
        'No branch selected for leave application.',
        userMessage: 'Select a branch before applying for leave.',
      );
    }
    if (role == UserRole.branchManager && branchId != null && branchId != id) {
      throw const BranchAuthorizationException(
        'Leave request must use the active branch.',
      );
    }
    final branch = _assigned(access, id);
    if (!branch.isActive) {
      throw const BranchAuthorizationException('Branch is not active.');
    }
    return branch;
  }

  BranchSummary forReview(
    UserAccessContext access, {
    required String? activeBranchId,
    required LeaveRequest request,
  }) {
    final organizationId = _requireOrganization(access);
    if (request.organizationId != organizationId) {
      throw const AccessDeniedException(
        'Leave request belongs to another organization.',
      );
    }
    switch (access.user.role) {
      case UserRole.orgAdmin:
        return _assigned(access, request.branchId);
      case UserRole.branchManager:
        if (request.applicantRole != UserRole.employee) {
          throw const AccessDeniedException(
            'Only Organization Admins may review a Branch Manager leave request.',
          );
        }
        final active = activeBranchId ?? access.activeBranch?.branchId;
        if (active == null || active != request.branchId) {
          throw const BranchAuthorizationException(
            'Leave request is outside the active branch.',
            userMessage: 'This leave request belongs to a different branch.',
          );
        }
        return _assigned(access, request.branchId);
      case UserRole.employee:
      case UserRole.platformOwner:
      case UserRole.platformAdmin:
        throw const AccessDeniedException(
          'Only managers may review leave requests.',
        );
    }
  }

  void assertCanEditPending(
    UserAccessContext access,
    LeaveRequest request, {
    String? activeBranchId,
  }) {
    if (request.applicantUid != access.user.id ||
        request.status != LeaveStatus.pending) {
      throw const AccessDeniedException(
        'Only the applicant may edit a pending leave request.',
      );
    }
    forSubmit(
      access,
      branchId: request.branchId,
      activeBranchId: activeBranchId,
    );
  }

  String _requireOrganization(UserAccessContext access) {
    final id = access.organization?.id;
    if (id == null || id.isEmpty) {
      throw const AccessDeniedException('No organization context.');
    }
    return id;
  }

  BranchSummary _assigned(UserAccessContext access, String id) {
    final branch = access.assignedBranches.where((b) => b.id == id).firstOrNull;
    if (branch == null) {
      throw const BranchAuthorizationException(
        'Branch is outside the assigned set.',
      );
    }
    return branch;
  }
}
