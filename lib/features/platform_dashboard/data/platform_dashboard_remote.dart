import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
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

/// Thin seam over SQL Connect so the repository can be tested with a fake.
abstract interface class PlatformDashboardRemote {
  Future<PlatformStats> loadStats();

  /// Newest organizations first, each with its branch and member counts.
  Future<List<RecentOrganizationSummary>> loadRecentOrganizations({
    required int limit,
  });
}

/// [PlatformDashboardRemote] backed by the generated connector.
class DataConnectPlatformDashboardRemote implements PlatformDashboardRemote {
  DataConnectPlatformDashboardRemote({this._connector});

  final WorkaxisConnectorConnector? _connector;

  WorkaxisConnectorConnector get _c =>
      _connector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<PlatformStats> loadStats() async {
    final data = (await _c.getPlatformStats().execute()).data;
    final byStatus = <String, int>{};
    for (final row in data.organizationsByStatus) {
      final key = row.status.toLowerCase();
      byStatus[key] = (byStatus[key] ?? 0) + row.count_;
    }
    return PlatformStats(
      organizationsByStatus: byStatus,
      platformAdminCount: data.platformAdminCount.fold<int>(
        0,
        (sum, r) => sum + r.count_,
      ),
    );
  }

  @override
  Future<List<RecentOrganizationSummary>> loadRecentOrganizations({
    required int limit,
  }) async {
    final page =
        (await _c.listOrganizationsPaged(limit: limit, offset: 0).execute())
            .data;
    // At most [limit] aggregate lookups, fetched in parallel.
    return Future.wait(
      page.organizations.map((o) async {
        final stats =
            (await _c.getOrganizationStats(orgId: o.id).execute()).data;
        return RecentOrganizationSummary(
          id: o.id,
          name: o.name,
          code: o.code,
          status: o.status,
          branchCount: stats.branchCount.fold<int>(0, (s, r) => s + r.count_),
          employeeCount: stats.memberCount.fold<int>(0, (s, r) => s + r.count_),
          createdAt: o.createdAt.toDateTime(),
        );
      }),
    );
  }
}
