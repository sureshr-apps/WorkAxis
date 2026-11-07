import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';

/// Stable repository contract for Branch Manager Overview.
abstract interface class BranchDashboardRepository {
  /// Metrics scoped strictly to [branchId], which must be a branch in
  /// [access]'s assigned set. Throws `NotFoundException` otherwise; it never
  /// falls back to another branch.
  Future<BranchDashboardSummary> getBranchDashboardSummary({
    required UserAccessContext access,
    required String branchId,
  });
}
