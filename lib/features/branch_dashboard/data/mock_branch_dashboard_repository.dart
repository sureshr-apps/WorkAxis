import 'package:workaxis/features/branch_dashboard/data/mock_branch_dashboard_data_source.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/branch_dashboard/domain/repositories/branch_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';

/// Mock repository implementation for Branch Manager Overview.
class MockBranchDashboardRepository implements BranchDashboardRepository {
  final MockBranchDashboardDataSource dataSource;
  final Duration delay;

  MockBranchDashboardRepository({
    MockBranchDashboardDataSource? dataSource,
    this.delay = const Duration(milliseconds: 300),
  }) : dataSource = dataSource ?? MockBranchDashboardDataSource();

  @override
  Future<BranchDashboardSummary> getBranchDashboardSummary(
    String branchId,
  ) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getBranchSummary(branchId);
  }

  @override
  Future<AttendanceSummary> getBranchAttendanceSummary(String branchId) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getBranchSummary(branchId).attendance;
  }

  @override
  Future<List<AttentionItem>> getBranchAttentionItems(String branchId) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getBranchSummary(branchId).attentionItems;
  }
}
