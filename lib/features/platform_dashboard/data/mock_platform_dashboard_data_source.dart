import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';

/// In-memory mock data source for platform overview data.
class MockPlatformDashboardDataSource {
  final MockPlatformOrganizationsDataSource _organizationsDataSource;
  final int platformAdminsCount;
  final int recentLimit;

  MockPlatformDashboardDataSource({
    MockPlatformOrganizationsDataSource? organizationsDataSource,
    this.platformAdminsCount = 4,
    this.recentLimit = 5,
  }) : _organizationsDataSource =
           organizationsDataSource ?? MockPlatformOrganizationsDataSource();

  MockPlatformOrganizationsDataSource get organizationsDataSource =>
      _organizationsDataSource;

  PlatformDashboardSummary getSummary() {
    final orgs = _organizationsDataSource.getOrganizations();
    final total = orgs.length;
    final active = orgs.where((o) => o.isActive).length;
    final suspended = orgs.where((o) => o.isSuspended).length;

    return PlatformDashboardSummary(
      totalOrganizations: total,
      activeOrganizations: active,
      suspendedOrganizations: suspended,
      platformAdminsCount: platformAdminsCount,
    );
  }

  /// The first organizations in the same order as the organizations list, so
  /// the mock dashboard and the Organizations tab show the same rows.
  List<CustomerOrganization> getRecentOrganizations({
    int? limit,
    String? query,
    OrganizationStatus? status,
  }) {
    final matches = _organizationsDataSource.getOrganizations(
      query: query,
      statusFilter: status,
    );
    return matches.take(limit ?? recentLimit).toList(growable: false);
  }
}
