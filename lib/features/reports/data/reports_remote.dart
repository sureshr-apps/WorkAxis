import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/features/reports/data/report_period_range.dart';

/// Return aggregates for a reporting window.
class ReportReturnStats {
  const ReportReturnStats({required this.byBranch, required this.byReason});

  /// Return count per branch id.
  final Map<String, int> byBranch;

  /// Return count per stored reason (the `returnReason` value).
  final Map<String, int> byReason;
}

/// Thin seam over the data gateway's aggregate queries used by reports, so the
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

/// [ReportsRemote] backed by the data gateway (`GetReturnCountsByBranch`,
/// `GetBranchStats`).
class DataConnectReportsRemote implements ReportsRemote {
  DataConnectReportsRemote({required this._gateway});

  final DataGateway _gateway;

  static String _ts(DateTime instant) => instant.toUtc().toIso8601String();

  @override
  Future<ReportReturnStats> returnStatsForOrganization(
    String organizationId,
    ReportRange range,
  ) async {
    final data = await _gateway.call('GetReturnCountsByBranch', {
      'orgId': organizationId,
      'from': _ts(range.from),
      'to': _ts(range.to),
    });
    return ReportReturnStats(
      byBranch: groupedCounts(data.objects('returnRecords'), 'branchId'),
      byReason: groupedCounts(data.objects('returnsByReason'), 'returnReason'),
    );
  }

  @override
  Future<ReportReturnStats> returnStatsForBranch(
    String branchId,
    ReportRange range,
  ) async {
    final data = await _gateway.call('GetBranchStats', {
      'branchId': branchId,
      'from': _ts(range.from),
      'to': _ts(range.to),
    });
    return ReportReturnStats(
      byBranch: {branchId: sumCounts(data.objects('returnsByStatus'))},
      byReason: groupedCounts(data.objects('returnsByReason'), 'returnReason'),
    );
  }
}
