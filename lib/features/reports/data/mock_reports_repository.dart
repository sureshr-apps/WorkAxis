import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/reports/data/mock_reports_data_source.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/domain/repositories/reports_repository.dart';

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
    String period = 'This Week',
  }) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    final isBranchManager = access.user.role == UserRole.branchManager;
    return _dataSource.getSummary(
      isBranchManager: isBranchManager,
      branchId: activeBranchId,
      period: period,
    );
  }
}
