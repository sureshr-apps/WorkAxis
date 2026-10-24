import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';

/// Permanent application contract for access resolution and branch scoping.
abstract interface class AccessRepository {
  /// Resolves the full access context (roles, organization, assigned branches, permissions)
  /// for the authenticated user.
  Future<UserAccessContext> resolveCurrentUserAccess(AppUser user);

  /// Retrieves the list of branches assigned to a given user.
  Future<List<BranchSummary>> getAssignedBranches(String userId);

  /// Validates whether a user is authorized to access a specific branch.
  Future<bool> validateBranchAccess({
    required String userId,
    required String branchId,
  });
}
