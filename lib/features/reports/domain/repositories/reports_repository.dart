import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';

abstract interface class ReportsRepository {
  Future<OperationalReportSummary> getReportSummary({
    required UserAccessContext access,
    String? activeBranchId,
    String period = 'This Week',
  });
}
