import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Role rules shared by the returns route loaders.
///
/// Organization admins and branch managers review returns; employees only
/// file and track their own.
bool canReviewReturns(UserRole role) =>
    role == UserRole.orgAdmin || role == UserRole.branchManager;

/// Eyebrow shown above a returns page, matching the role's list screen.
String returnsEyebrow(UserRole role) => switch (role) {
  UserRole.employee => 'Self Service Operations',
  UserRole.branchManager => 'Branch Operations',
  _ => 'Inventory & Returns',
};

/// Branch that returns reads and writes are scoped to. Employees are not
/// branch-scoped on the returns list, so they get none.
String? returnsBranchScope(UserRole role, String? activeBranchId) =>
    role == UserRole.employee ? null : activeBranchId;
