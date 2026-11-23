import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/models/return_status_counts.dart';

/// Thin seam over the data gateway return operations so [SqlConnectReturnsRepository]
/// can be tested with a fake. Implementations perform no authorization; the
/// repository decides which operation to call for the caller's role.
///
/// List methods return one page plus the server total. [query] is a
/// case-insensitive search over product, invoice, bill, submitter and branch.
abstract interface class ReturnsRemote {
  /// `ListMyReturns`: rows where the submitter is the signed-in user.
  Future<PageResult<ReturnItem>> listMine({
    required String organizationId,
    required String employeeUid,
    required int limit,
    int offset = 0,
    ReturnStatus? status,
    String? query,
  });

  /// `ListReturnsByBranchPaged` for [branch]; [queue] keeps the caller's own
  /// returns or everyone else's (null: the whole branch).
  Future<PageResult<ReturnItem>> listByBranch({
    required String organizationId,
    required BranchSummary branch,
    required int limit,
    int offset = 0,
    ReturnQueue? queue,
    ReturnStatus? status,
    String? query,
  });

  /// `ListReturnsByOrgPaged`: every branch of the organization (Org Admin),
  /// optionally narrowed to [branchId]. Branch names come from the response.
  Future<PageResult<ReturnItem>> listByOrganization({
    required String organizationId,
    required int limit,
    int offset = 0,
    String? branchId,
    ReturnStatus? status,
    String? query,
  });

  /// `GetReturnStatusCounts` for the caller's own returns.
  Future<ReturnStatusCounts> countMine();

  /// `GetReturnStatusCounts` for [branchId], optionally one [queue].
  Future<ReturnStatusCounts> countByBranch({
    required String branchId,
    ReturnQueue? queue,
  });

  /// `GetReturnStatusCounts` for the organization, optionally one branch.
  Future<ReturnStatusCounts> countByOrganization({
    required String organizationId,
    String? branchId,
  });

  /// `GetReturnById`; null when missing or outside the caller's scope.
  Future<ReturnItem?> getById({
    required String organizationId,
    required String returnId,
  });

  /// `SubmitReturnBatch`: saves every line of one bill in a single server
  /// transaction (all or nothing) and returns the new ids in line order.
  /// Submitter and organization are derived on the server.
  Future<List<String>> submitBatch({
    required String branchId,
    required CreateReturnBatchInput input,
  });

  /// Updates a return submitted by the authenticated member, while pending.
  Future<void> update({
    required String returnId,
    required CreateReturnInput input,
  });

  /// `UpdateReturnRecordReview`; the reviewer is derived on the server.
  Future<void> review({
    required String returnId,
    required ReturnStatus decision,
    String? reviewerNotes,
  });
}
