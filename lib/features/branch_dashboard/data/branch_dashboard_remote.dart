import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';

/// Aggregate counts for one branch (from `GetBranchStats`).
class BranchCounts {
  const BranchCounts({
    required this.memberCount,
    required this.returnsByStatus,
  });

  /// Members assigned to the branch.
  final int memberCount;

  /// Return count per lower-cased status.
  final Map<String, int> returnsByStatus;

  int returns(String status) => returnsByStatus[status] ?? 0;
}

/// Thin seam over SQL Connect so the repository can be tested with a fake.
abstract interface class BranchDashboardRemote {
  Future<BranchCounts> loadCounts(String branchId);
}

/// [BranchDashboardRemote] backed by the generated connector.
class DataConnectBranchDashboardRemote implements BranchDashboardRemote {
  DataConnectBranchDashboardRemote({this._connector});

  final WorkaxisConnectorConnector? _connector;

  WorkaxisConnectorConnector get _c =>
      _connector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<BranchCounts> loadCounts(String branchId) async {
    final data = (await _c.getBranchStats(branchId: branchId).execute()).data;
    final byStatus = <String, int>{};
    for (final row in data.returnsByStatus) {
      final key = row.status.toLowerCase();
      byStatus[key] = (byStatus[key] ?? 0) + row.count_;
    }
    return BranchCounts(
      memberCount: data.memberCount.fold<int>(0, (sum, r) => sum + r.count_),
      returnsByStatus: byStatus,
    );
  }
}
