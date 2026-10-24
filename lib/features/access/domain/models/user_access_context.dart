import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Resolved access boundaries and context for an authenticated user.
class UserAccessContext {
  const UserAccessContext({
    required this.user,
    this.organization,
    this.assignedBranches = const [],
    this.activeBranch,
    this.permissions = const {},
  });

  final AppUser user;
  final OrganizationSummary? organization;
  final List<BranchSummary> assignedBranches;
  final ActiveBranchContext? activeBranch;
  final Set<String> permissions;

  /// Active (non-disabled) assigned branches for the user.
  List<BranchSummary> get activeAssignedBranches =>
      assignedBranches.where((b) => b.isActive).toList();

  bool get hasMultipleAssignedBranches => activeAssignedBranches.length > 1;
  bool get hasSingleAssignedBranch => activeAssignedBranches.length == 1;
  bool get hasNoAssignedBranches => activeAssignedBranches.isEmpty;

  /// Indicates whether this user is a Branch Manager needing branch selection.
  bool get requiresBranchSelection {
    if (user.role != UserRole.branchManager) return false;
    return activeBranch == null && hasMultipleAssignedBranches;
  }

  UserAccessContext copyWith({
    AppUser? user,
    OrganizationSummary? organization,
    List<BranchSummary>? assignedBranches,
    ActiveBranchContext? activeBranch,
    Set<String>? permissions,
  }) {
    return UserAccessContext(
      user: user ?? this.user,
      organization: organization ?? this.organization,
      assignedBranches: assignedBranches ?? this.assignedBranches,
      activeBranch: activeBranch ?? this.activeBranch,
      permissions: permissions ?? this.permissions,
    );
  }
}
