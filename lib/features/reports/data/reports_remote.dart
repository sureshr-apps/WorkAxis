import 'package:firebase_data_connect/firebase_data_connect.dart'
    show Timestamp;
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/reports/data/report_period_range.dart';

/// Return aggregates for a reporting window.
class ReportReturnStats {
  const ReportReturnStats({required this.byBranch, required this.byReason});

  /// Return count per branch id.
  final Map<String, int> byBranch;

  /// Return count per stored reason (the `returnReason` value).
  final Map<String, int> byReason;
}

/// Thin seam over SQL Connect aggregate queries used by reports, so the
/// repository can be tested with a fake.
abstract interface class ReportsRemote {
  /// Returns per branch and per reason for the organization within [range]
  /// (`GetReturnCountsByBranch`; Org Admin / platform only).
  Future<ReportReturnStats> returnStatsForOrganization(
    String organizationId,
    ReportRange range,
  );

  /// Returns of one branch within [range] (`GetBranchStats`); `byBranch`
  /// holds the single branch total.
  Future<ReportReturnStats> returnStatsForBranch(
    String branchId,
    ReportRange range,
  );
}

/// [ReportsRemote] backed by the generated connector.
class DataConnectReportsRemote implements ReportsRemote {
  DataConnectReportsRemote({this._connector});

  final WorkaxisConnectorConnector? _connector;

  WorkaxisConnectorConnector get _c =>
      _connector ?? WorkaxisConnectorConnector.instance;

  static Timestamp _ts(DateTime instant) =>
      Timestamp(0, instant.millisecondsSinceEpoch ~/ 1000);

  @override
  Future<ReportReturnStats> returnStatsForOrganization(
    String organizationId,
    ReportRange range,
  ) async {
    final data =
        (await _c
                .getReturnCountsByBranch(orgId: organizationId)
                .from(_ts(range.from))
                .to(_ts(range.to))
                .execute())
            .data;
    final byBranch = <String, int>{};
    for (final row in data.returnRecords) {
      byBranch[row.branchId] = (byBranch[row.branchId] ?? 0) + row.count_;
    }
    final byReason = <String, int>{};
    for (final row in data.returnsByReason) {
      byReason[row.returnReason] =
          (byReason[row.returnReason] ?? 0) + row.count_;
    }
    return ReportReturnStats(byBranch: byBranch, byReason: byReason);
  }

  @override
  Future<ReportReturnStats> returnStatsForBranch(
    String branchId,
    ReportRange range,
  ) async {
    final data =
        (await _c
                .getBranchStats(branchId: branchId)
                .from(_ts(range.from))
                .to(_ts(range.to))
                .execute())
            .data;
    final byReason = <String, int>{};
    for (final row in data.returnsByReason) {
      byReason[row.returnReason] =
          (byReason[row.returnReason] ?? 0) + row.count_;
    }
    final total = data.returnsByStatus.fold<int>(0, (s, r) => s + r.count_);
    return ReportReturnStats(byBranch: {branchId: total}, byReason: byReason);
  }
}
