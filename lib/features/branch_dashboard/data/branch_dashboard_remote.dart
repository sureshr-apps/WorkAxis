import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';

/// Aggregate counts for one branch (from `GetBranchStats`).
class BranchCounts {
  const BranchCounts({
    required this.memberCount,
    required this.scheduledMemberCount,
    required this.returnsByStatus,
  });

  /// Members assigned to the branch.
  final int memberCount;

  /// Active employees assigned here whose weekly schedule includes today.
  final int scheduledMemberCount;

  /// Return count per lower-cased status.
  final Map<String, int> returnsByStatus;

  int returns(String status) => returnsByStatus[status] ?? 0;
}

/// Thin seam over the data gateway so the repository can be tested with a fake.
abstract interface class BranchDashboardRemote {
  Future<BranchCounts> loadCounts(String branchId);
}

/// [BranchDashboardRemote] backed by the data gateway (`GetBranchStats`).
class DataConnectBranchDashboardRemote implements BranchDashboardRemote {
  DataConnectBranchDashboardRemote({required this._gateway});

  final DataGateway _gateway;

  @override
  Future<BranchCounts> loadCounts(String branchId) async {
    final data = await _gateway.call('GetBranchStats', {'branchId': branchId});
    return BranchCounts(
      memberCount: sumCounts(data.objects('memberCount')),
      scheduledMemberCount: sumCounts(data.objects('scheduledMemberCount')),
      returnsByStatus: groupedCounts(
        data.objects('returnsByStatus'),
        'status',
        lowerCaseKeys: true,
      ),
    );
  }
}
