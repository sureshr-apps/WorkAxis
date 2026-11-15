import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/features/platform_dashboard/data/platform_dashboard_remote.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';
import 'package:workaxis/features/platform_dashboard/domain/repositories/platform_dashboard_repository.dart';

/// Production [PlatformDashboardRepository]. Summary counts come from the data
/// gateway aggregates (`GetPlatformStats`). Recent organizations come from the
/// organizations repository, so they match the Organizations tab exactly.
class SqlConnectPlatformDashboardRepository
    implements PlatformDashboardRepository {
  SqlConnectPlatformDashboardRepository({
    DataGateway? gateway,
    PlatformDashboardRemote? remote,
    required this._organizations,
    this.recentLimit = 5,
  }) : assert(
         gateway != null || remote != null,
         'Provide a data gateway or a remote.',
       ),
       _remote =
           remote ?? DataConnectPlatformDashboardRemote(gateway: gateway!);

  final PlatformDashboardRemote _remote;
  final PlatformOrganizationsRepository _organizations;

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
  Future<List<CustomerOrganization>> getRecentOrganizations({
    String? query,
    OrganizationStatus? status,
  }) async {
    try {
      final page = await _organizations.getOrganizationsPage(
        query: query,
        statusFilter: status,
        limit: recentLimit,
      );
      return page.items;
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
