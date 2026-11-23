import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// One server-side list of leave requests. Each queue maps to exactly one
/// server scope, so no client-side merging is needed.
enum LeaveQueue {
  /// The caller's own requests (Employee or Branch Manager).
  mine,

  /// Employee requests of the Branch Manager's active branch.
  branchEmployees,

  /// Every request in the Organization Admin's organization.
  organization;

  /// Scope value understood by `GetLeaveStatusCounts`.
  String get scopeName => name;

  /// Queue shown first for [role]; null when the role has no leave queue.
  static LeaveQueue? defaultFor(UserRole role) => switch (role) {
    UserRole.employee || UserRole.branchManager => LeaveQueue.mine,
    UserRole.orgAdmin => LeaveQueue.organization,
    UserRole.platformOwner || UserRole.platformAdmin => null,
  };

  /// Whether [role] may read this queue.
  bool isAvailableTo(UserRole role) => switch (this) {
    LeaveQueue.mine =>
      role == UserRole.employee || role == UserRole.branchManager,
    LeaveQueue.branchEmployees => role == UserRole.branchManager,
    LeaveQueue.organization => role == UserRole.orgAdmin,
  };
}
