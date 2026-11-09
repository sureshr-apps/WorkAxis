import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/reports/data/report_period_range.dart';
import 'package:workaxis/features/reports/data/reports_remote.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/domain/models/report_period.dart';
import 'package:workaxis/features/reports/domain/repositories/reports_repository.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

/// Production [ReportsRepository].
///
/// Only figures the backend can actually compute are reported: return totals
/// per branch and per reason from aggregate queries scoped to the selected
/// period (one query for an organization, not one per branch). Attendance
/// rates, hours and exceptions need data that does not exist yet (shift
/// schedules, attendance aggregation by period), so they stay null/empty
/// instead of being invented.
class SqlConnectReportsRepository implements ReportsRepository {
  SqlConnectReportsRepository({
    WorkaxisConnectorConnector? connector,
    ReportsRemote? remote,
    Now? now,
  }) : _remote = remote ?? DataConnectReportsRemote(connector: connector),
       _now = now ?? systemNow;

  final ReportsRemote _remote;
  final Now _now;

  @override
  Future<OperationalReportSummary> getReportSummary({
    required UserAccessContext access,
    String? activeBranchId,
    ReportPeriod period = ReportPeriod.thisWeek,
  }) async {
    try {
      final orgId = access.organization?.id;
      if (orgId == null || orgId.isEmpty) {
        throw const AccessDeniedException('No organization context.');
      }
      final range = ReportPeriodRange.resolve(period, _now);

      final List<BranchSummary> branches;
      final ReportReturnStats stats;
      switch (access.user.role) {
        case UserRole.orgAdmin:
          if (activeBranchId == null) {
            branches = access.assignedBranches;
            stats = await _remote.returnStatsForOrganization(orgId, range);
          } else {
            final branch = _assigned(access, activeBranchId);
            branches = [branch];
            stats = await _remote.returnStatsForBranch(branch.id, range);
          }
        case UserRole.branchManager:
          final branchId = activeBranchId ?? access.activeBranch?.branchId;
          if (branchId == null) {
            throw const BranchAuthorizationException(
              'Branch Manager has no active branch.',
              userMessage: 'Select a branch to view its report.',
            );
          }
          final branch = _assigned(access, branchId);
          branches = [branch];
          stats = await _remote.returnStatsForBranch(branch.id, range);
        default:
          throw const AccessDeniedException(
            'Reports require a Branch Manager or Organization Admin.',
          );
      }

      final metrics = [
        for (final b in branches)
          BranchPerformanceMetric(
            branchId: b.id,
            branchName: b.name,
            returnCount: stats.byBranch[b.id] ?? 0,
          ),
      ];
      return OperationalReportSummary(
        period: period,
        returnVolume: stats.byBranch.values.fold(
          0,
          (sum, count) => sum + count,
        ),
        returnCountsCoverPeriod: true,
        branchMetrics: metrics,
        returnCategories: _categories(stats.byReason),
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  /// Groups stored reasons into the known categories, largest first.
  List<CategoryReturnMetric> _categories(Map<String, int> byReason) {
    final counts = <ReturnReason, int>{};
    byReason.forEach((raw, count) {
      final reason = ReturnReason.parse(raw);
      counts[reason] = (counts[reason] ?? 0) + count;
    });
    final total = counts.values.fold(0, (sum, c) => sum + c);
    if (total == 0) return const [];
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries)
        CategoryReturnMetric(
          categoryName: e.key.label,
          count: e.value,
          percentage: e.value * 100 / total,
        ),
    ];
  }

  BranchSummary _assigned(UserAccessContext access, String branchId) {
    final branch = access.assignedBranches
        .where((b) => b.id == branchId)
        .firstOrNull;
    if (branch == null) {
      throw const BranchAuthorizationException(
        'Branch is outside the assigned set.',
      );
    }
    return branch;
  }
}
