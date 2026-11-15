import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';

/// Platform-wide aggregates (from `GetPlatformStats`).
class PlatformStats {
  const PlatformStats({
    required this.organizationsByStatus,
    required this.platformAdminCount,
  });

  /// Organization count per lower-cased status.
  final Map<String, int> organizationsByStatus;

  /// Members with role `platformOwner` or `platformAdmin`.
  final int platformAdminCount;
}

/// Thin seam over the data gateway so the repository can be tested with a fake.
abstract interface class PlatformDashboardRemote {
  Future<PlatformStats> loadStats();

  /// Newest organizations first, each with its branch and member counts.
  Future<List<RecentOrganizationSummary>> loadRecentOrganizations({
    required int limit,
  });
}

/// [PlatformDashboardRemote] backed by the data gateway (`GetPlatformStats`,
/// `ListOrganizationsPaged`, `GetOrganizationStats`).
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

  @override
  Future<List<RecentOrganizationSummary>> loadRecentOrganizations({
    required int limit,
  }) async {
    final page = await _gateway.call('ListOrganizationsPaged', {
      'limit': limit,
      'offset': 0,
    });
    // At most [limit] aggregate lookups, fetched in parallel.
    return Future.wait(
      page.objects('organizations').map((o) async {
        final id = o.string('id');
        final stats = await _gateway.call('GetOrganizationStats', {
          'orgId': id,
        });
        return RecentOrganizationSummary(
          id: id,
          name: o.string('name'),
          code: o.string('code'),
          status: o.string('status'),
          branchCount: sumCounts(stats.objects('branchCount')),
          employeeCount: sumCounts(stats.objects('memberCount')),
          createdAt: o.dateTime('createdAt'),
        );
      }),
    );
  }
}
