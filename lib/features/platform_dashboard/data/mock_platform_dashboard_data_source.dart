import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

/// In-memory mock data source for platform overview data.
class MockPlatformDashboardDataSource {
  final MockPlatformOrganizationsDataSource _organizationsDataSource;
  final int platformAdminsCount;
  final int recentLimit;

  MockPlatformDashboardDataSource({
    MockPlatformOrganizationsDataSource? organizationsDataSource,
    this.platformAdminsCount = 4,
    this.recentLimit = 4,
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

  List<RecentOrganizationSummary> getRecentOrganizations({int? limit}) {
    final effectiveLimit = limit ?? recentLimit;
    final orgs = List<CustomerOrganization>.from(
      _organizationsDataSource.getOrganizations(),
    );

    // Order newest createdAt first
    orgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orgs.take(effectiveLimit).map((org) {
      final email =
          (org.contactEmail != null && org.contactEmail!.trim().isNotEmpty)
          ? org.contactEmail!.trim()
          : (org.admins.isNotEmpty ? org.admins.first.email.trim() : '');

      return RecentOrganizationSummary(
        id: org.id,
        name: org.name,
        code: org.code,
        adminEmail: email,
        status: org.status.name,
        branchCount: org.branchCount,
        employeeCount: org.employeeCount,
        createdAt: org.createdAt,
      );
    }).toList();
  }
}
