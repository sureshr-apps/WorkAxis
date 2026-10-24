import 'package:workaxis/features/access/domain/models/branch_summary.dart';

/// Application-level active branch context for branch-scoped workflows.
class ActiveBranchContext {
  const ActiveBranchContext({
    required this.branchId,
    required this.branchName,
    required this.branchCode,
    required this.organizationId,
  });

  factory ActiveBranchContext.fromBranch(BranchSummary branch) {
    return ActiveBranchContext(
      branchId: branch.id,
      branchName: branch.name,
      branchCode: branch.code,
      organizationId: branch.organizationId,
    );
  }

  final String branchId;
  final String branchName;
  final String branchCode;
  final String organizationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveBranchContext &&
          runtimeType == other.runtimeType &&
          branchId == other.branchId &&
          organizationId == other.organizationId;

  @override
  int get hashCode => Object.hash(branchId, organizationId);
}
