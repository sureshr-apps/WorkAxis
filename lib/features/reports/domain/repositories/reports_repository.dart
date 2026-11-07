import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/domain/models/report_period.dart';

/// Operational reports scoped by the caller's [UserAccessContext]: Branch
/// Managers see their active branch, Organization Admins their organization.
abstract interface class ReportsRepository {
  Future<OperationalReportSummary> getReportSummary({
    required UserAccessContext access,
    String? activeBranchId,
    ReportPeriod period = ReportPeriod.thisWeek,
  });
}
