import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/models/return_status_counts.dart';

/// Return requests, scoped by the caller's [UserAccessContext]:
///
/// * Employees see only their own returns.
/// * Branch Managers see the active branch, which must be in their assigned
///   set.
/// * Organization Admins see their organization (all branches, or one).
/// * Platform users have no returns scope.
abstract interface class ReturnsRepository {
  /// One page of the returns visible to [access], newest return date first.
  /// [activeBranchId] is the active branch context; it is required for Branch
  /// Managers with several branches and optional for Organization Admins.
  /// [queue] splits a Branch Manager's branch into their own and others'
  /// returns (null: the whole branch); other roles ignore it. [status] and
  /// [query] (product, invoice, bill, submitter or branch) narrow the page.
  Future<PageResult<ReturnItem>> getReturnsPage({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnQueue? queue,
    ReturnStatus? status,
    String? query,
    int offset = 0,
    int limit = defaultPageSize,
  });

  /// Status totals for the same scope as [getReturnsPage], ignoring status
  /// and search filters.
  Future<ReturnStatusCounts> getReturnCounts({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnQueue? queue,
  });

  /// One return visible to [access], or null when it does not exist or is
  /// outside the caller's scope (deep links, detail pages).
  Future<ReturnItem?> getReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required String returnId,
  });

  /// Submits a return for [branchId] (default: active or only assigned
  /// branch). Employees and Branch Managers only. The submitter is derived
  /// from the authenticated session on the server.
  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  });

  /// Submits one or more returned items sharing the same bill/invoice header.
  Future<List<ReturnItem>> submitReturnBatch({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnBatchInput input,
  });

  /// Updates one pending return filed by the current employee or Branch
  /// Manager. The server verifies ownership and pending status again.
  Future<void> updateReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required CreateReturnInput input,
  });

  /// Approves or rejects a pending [returnItem]. Organization Admins of its
  /// organization, or another Branch Manager assigned to its branch, may review
  /// it. A Branch Manager cannot review their own submission. The reviewer is
  /// derived server-side from the authenticated session.
  Future<ReturnItem> reviewReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required ReturnStatus decision,
    String? reviewerNotes,
  });
}
