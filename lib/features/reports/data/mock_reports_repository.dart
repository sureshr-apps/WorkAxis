import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/reports/data/mock_reports_data_source.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/domain/models/report_period.dart';
import 'package:workaxis/features/reports/domain/repositories/reports_repository.dart';

/// Mock reports repository with the same scoping as production: Branch
/// Managers get their active assigned branch, Org Admins the organization.
class MockReportsRepository implements ReportsRepository {
  final MockReportsDataSource _dataSource;
  final Duration delay;

  MockReportsRepository({
    MockReportsDataSource? dataSource,
    this.delay = const Duration(milliseconds: 60),
  }) : _dataSource = dataSource ?? MockReportsDataSource();

  @override
  Future<OperationalReportSummary> getReportSummary({
    required UserAccessContext access,
    String? activeBranchId,
    ReportPeriod period = ReportPeriod.thisWeek,
  }) async {
    if (access.organization == null) {
      throw const AccessDeniedException('No organization context.');
    }
    final List<BranchSummary> branches;
    switch (access.user.role) {
      case UserRole.orgAdmin:
        branches = activeBranchId == null
            ? access.assignedBranches
            : access.assignedBranches
                  .where((b) => b.id == activeBranchId)
                  .toList();
      case UserRole.branchManager:
        final id = activeBranchId ?? access.activeBranch?.branchId;
        branches = access.assignedBranches.where((b) => b.id == id).toList();
        if (branches.isEmpty) {
          throw const BranchAuthorizationException(
            'Branch is outside the assigned set.',
          );
        }
      default:
        throw const AccessDeniedException(
          'Reports require a Branch Manager or Organization Admin.',
        );
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return _dataSource.getSummary(branches: branches, period: period);
  }
}
