import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Which slice of the asset register a list shows. Each queue maps to one
/// server listing, so pages never need merging.
enum AssetQueue {
  /// Assets held by the signed-in user (Employee, or a Branch Manager's own
  /// assets at the active branch).
  mine,

  /// Assets held by the employees of a Branch Manager's active branch.
  branchEmployees,

  /// Every asset in an Org Admin's organization.
  organization;

  /// Queues [role] may read; empty when the role has no asset access.
  static List<AssetQueue> allowedFor(UserRole role) => switch (role) {
    UserRole.employee => const [AssetQueue.mine],
    UserRole.branchManager => const [
      AssetQueue.mine,
      AssetQueue.branchEmployees,
    ],
    UserRole.orgAdmin => const [AssetQueue.organization],
    UserRole.platformOwner || UserRole.platformAdmin => const [],
  };

  /// The queue a list opens on for [role], or null without asset access.
  static AssetQueue? defaultFor(UserRole role) {
    final allowed = allowedFor(role);
    return allowed.isEmpty ? null : allowed.first;
  }
}
