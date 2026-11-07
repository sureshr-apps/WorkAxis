import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

/// Thin seam over SQL Connect return operations so [SqlConnectReturnsRepository]
/// can be tested with a fake. Implementations perform no authorization; the
/// repository decides which operation to call for the caller's role.
abstract interface class ReturnsRemote {
  /// `ListMyReturns`: rows where the submitter is the signed-in user.
  Future<List<ReturnItem>> listMine({
    required String organizationId,
    required String employeeUid,
    required int limit,
    ReturnStatus? status,
  });

  /// `ListReturnsByBranchPaged` for [branch].
  Future<List<ReturnItem>> listByBranch({
    required String organizationId,
    required BranchSummary branch,
    required int limit,
    ReturnStatus? status,
  });

  /// `ListReturnsByOrgPaged`: every branch of the organization (Org Admin),
  /// optionally narrowed to [branchId]. Branch names come from the response.
  Future<List<ReturnItem>> listByOrganization({
    required String organizationId,
    required int limit,
    String? branchId,
    ReturnStatus? status,
  });

  /// `SubmitReturn`; returns the new return's id. Submitter and organization
  /// are derived on the server.
  Future<String> submit({
    required String branchId,
    required CreateReturnInput input,
  });

  /// `UpdateReturnRecordReview`; the reviewer is derived on the server.
  Future<void> review({
    required String returnId,
    required ReturnStatus decision,
    String? reviewerNotes,
  });
}
