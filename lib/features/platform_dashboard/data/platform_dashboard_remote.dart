import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';

/// Platform-wide aggregates (from `GetPlatformStats`).
class PlatformStats {
  const PlatformStats({
    required this.organizationsByStatus,
    required this.platformAdminCount,
  });

  /// Organization count per lower-cased status.
  final Map<String, int> organizationsByStatus;

  /// Members with role `platformAdmin` (the Platform Owner is excluded).
  final int platformAdminCount;
}

/// Thin seam over the data gateway so the repository can be tested with a fake.
///
/// The recent organizations are not loaded here: they come from the same
/// organizations query the Organizations tab uses.
abstract interface class PlatformDashboardRemote {
  Future<PlatformStats> loadStats();
}

/// [PlatformDashboardRemote] backed by the data gateway (`GetPlatformStats`).
class DataConnectPlatformDashboardRemote implements PlatformDashboardRemote {
  DataConnectPlatformDashboardRemote({required this._gateway});

  final DataGateway _gateway;

  @override
  Future<PlatformStats> loadStats() async {
    final data = await _gateway.call('GetPlatformStats');
    return PlatformStats(
      organizationsByStatus: groupedCounts(
        data.objects('organizationsByStatus'),
        'status',
        lowerCaseKeys: true,
      ),
      platformAdminCount: sumCounts(data.objects('platformAdminCount')),
    );
  }
}
