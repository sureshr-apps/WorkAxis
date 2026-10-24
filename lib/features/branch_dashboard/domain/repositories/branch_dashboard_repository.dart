import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';

/// Stable repository contract for Branch Manager Overview.
abstract interface class BranchDashboardRepository {
  /// Fetches metrics scoped strictly to [branchId].
  Future<BranchDashboardSummary> getBranchDashboardSummary(String branchId);

  /// Fetches attendance metrics scoped strictly to [branchId].
  Future<AttendanceSummary> getBranchAttendanceSummary(String branchId);

  /// Fetches attention items scoped strictly to [branchId].
  Future<List<AttentionItem>> getBranchAttentionItems(String branchId);
}
