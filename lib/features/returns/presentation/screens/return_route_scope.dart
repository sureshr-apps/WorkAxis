import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

/// Role rules shared by the returns route loaders.
///
/// Organization admins and branch managers review returns; employees only
/// file and track their own. A Branch Manager cannot review their own return.
bool canReviewReturns(UserRole role) =>
    role == UserRole.orgAdmin || role == UserRole.branchManager;

/// Hides review controls when a Branch Manager is looking at their own return.
/// The repository and backend enforce the same rule for direct requests.
bool canReviewReturn(UserRole role, String reviewerUid, ReturnItem item) =>
    canReviewReturns(role) &&
    (role != UserRole.branchManager || !item.wasSubmittedBy(reviewerUid));

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
