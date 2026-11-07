import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

/// Return requests, scoped by the caller's [UserAccessContext]:
///
/// * Employees see only their own returns.
/// * Branch Managers see the active branch, which must be in their assigned
///   set.
/// * Organization Admins see their organization (all branches, or one).
/// * Platform users have no returns scope.
abstract interface class ReturnsRepository {
  /// Returns visible to [access], newest first. [activeBranchId] is the
  /// active branch context; it is required for Branch Managers with several
  /// branches and optional for Organization Admins.
  Future<List<ReturnItem>> getReturns({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnStatus? statusFilter,
  });

  /// Submits a return for [branchId] (default: active or only assigned
  /// branch). Employees and Branch Managers only. The submitter is derived
  /// from the authenticated session on the server.
  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  });

  /// Approves or rejects a pending [returnItem]. Organization Admins of its
  /// organization, or the Branch Manager whose active branch it belongs to.
  /// The reviewer is derived server-side from the authenticated session.
  Future<ReturnItem> reviewReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required ReturnStatus decision,
    String? reviewerNotes,
  });
}
