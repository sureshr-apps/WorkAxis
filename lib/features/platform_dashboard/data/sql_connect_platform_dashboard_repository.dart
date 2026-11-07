import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/platform_dashboard/data/platform_dashboard_remote.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/repositories/platform_dashboard_repository.dart';

/// Production [PlatformDashboardRepository] using SQL Connect aggregates
/// (`GetPlatformStats`, `ListOrganizationsPaged`, `GetOrganizationStats`).
class SqlConnectPlatformDashboardRepository
    implements PlatformDashboardRepository {
  SqlConnectPlatformDashboardRepository({
    WorkaxisConnectorConnector? connector,
    PlatformDashboardRemote? remote,
    this.recentLimit = 5,
  }) : _remote =
           remote ?? DataConnectPlatformDashboardRemote(connector: connector);

  final PlatformDashboardRemote _remote;

  /// How many organizations the "recent" list shows.
  final int recentLimit;

  @override
  Future<PlatformDashboardSummary> getPlatformDashboardSummary() async {
    try {
      final stats = await _remote.loadStats();
      final byStatus = stats.organizationsByStatus;
      return PlatformDashboardSummary(
        totalOrganizations: byStatus.values.fold(0, (a, b) => a + b),
        activeOrganizations: byStatus['active'] ?? 0,
        suspendedOrganizations: byStatus['suspended'] ?? 0,
        platformAdminsCount: stats.platformAdminCount,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<List<RecentOrganizationSummary>> getRecentOrganizations() async {
    try {
      return await _remote.loadRecentOrganizations(limit: recentLimit);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
