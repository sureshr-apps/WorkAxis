import 'package:workaxis/features/access/domain/models/access_member_record.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';

/// Remote reads needed to resolve access. Thin seam over SQL Connect so the
/// repository logic can be unit-tested with a fake.
abstract interface class AccessRemoteDataSource {
  /// The signed-in caller's membership row, or null when none exists.
  Future<AccessMemberRecord?> fetchMyMember();

  /// Active branches assigned to the caller (`ListMyBranchAssignments`).
  Future<List<BranchSummary>> fetchMyAssignedBranches();

  /// Branches of [organizationId] (`ListBranchesByOrg`).
  Future<List<BranchSummary>> fetchOrganizationBranches(String organizationId);
}
