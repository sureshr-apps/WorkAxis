import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/app_permission.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Pure access rules shared by the mock and production access repositories,
/// so both resolve exactly the same context for the same facts.
///
/// - Only active members of active organizations are granted access.
/// - Platform roles have no organization or branches.
/// - Organization Admins are organization-wide: every active organization
///   branch is in scope and no active branch is pre-selected.
/// - Branch Managers get their active assigned branches; a single one is
///   selected automatically, several require an explicit choice.
/// - Employees get their active assigned branches and work in the first one.
class AccessResolver {
  AccessResolver._();

  static UserAccessContext resolve({
    required AppUser user,
    OrganizationSummary? organization,
    List<BranchSummary> branches = const [],
  }) {
    if (user.status != AccountStatus.active) {
      throw const AccessDeniedException(
        'Member is not active',
        'Your account is not active. Please contact your administrator.',
      );
    }

    final permissions = AppPermissionSet.forRole(user.role);

    if (user.isPlatformLevel) {
      return UserAccessContext(user: user, permissions: permissions);
    }

    if (organization == null) {
      throw const AccessResolutionException(
        'Customer user is missing organization membership.',
      );
    }
    if (!organization.isActive) {
      throw const AccessDeniedException(
        'Organization is suspended',
        'Your organization is suspended. Please contact your administrator.',
      );
    }

    final scoped = branches
        .where((b) => b.isActive && b.organizationId == organization.id)
        .toList(growable: false);

    ActiveBranchContext? active;
    switch (user.role) {
      case UserRole.branchManager:
        if (scoped.length == 1) {
          active = ActiveBranchContext.fromBranch(scoped.single);
        }
      case UserRole.employee:
        if (scoped.isNotEmpty) {
          active = ActiveBranchContext.fromBranch(scoped.first);
        }
      default:
        break;
    }

    return UserAccessContext(
      user: user,
      organization: organization,
      assignedBranches: scoped,
      activeBranch: active,
      permissions: permissions,
    );
  }
}
