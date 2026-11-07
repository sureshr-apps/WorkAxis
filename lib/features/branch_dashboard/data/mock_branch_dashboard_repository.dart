import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/branch_dashboard/data/mock_branch_dashboard_data_source.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/branch_dashboard/domain/repositories/branch_dashboard_repository.dart';

/// Mock repository implementation for Branch Manager Overview.
///
/// Mirrors the real repository's scoping: the branch must be in the user's
/// assigned set, otherwise the branch is reported as not found.
class MockBranchDashboardRepository implements BranchDashboardRepository {
  final MockBranchDashboardDataSource dataSource;
  final Duration delay;

  MockBranchDashboardRepository({
    MockBranchDashboardDataSource? dataSource,
    this.delay = const Duration(milliseconds: 300),
  }) : dataSource = dataSource ?? MockBranchDashboardDataSource();

  @override
  Future<BranchDashboardSummary> getBranchDashboardSummary({
    required UserAccessContext access,
    required String branchId,
  }) async {
    final role = access.user.role;
    if (role != UserRole.branchManager && role != UserRole.orgAdmin) {
      throw const AccessDeniedException(
        'Branch dashboard requires a Branch Manager or Organization Admin.',
      );
    }
    final branch = access.assignedBranches
        .where((b) => b.id == branchId)
        .firstOrNull;
    if (branch == null) {
      throw const NotFoundException('Branch not found.');
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getBranchSummary(branch);
  }
}
