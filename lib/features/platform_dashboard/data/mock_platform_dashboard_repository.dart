import 'package:workaxis/features/platform_dashboard/data/mock_platform_dashboard_data_source.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/repositories/platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';

/// Mock repository implementation for platform overview data.
class MockPlatformDashboardRepository implements PlatformDashboardRepository {
  final MockPlatformDashboardDataSource dataSource;
  final Duration delay;

  MockPlatformDashboardRepository({
    MockPlatformDashboardDataSource? dataSource,
    MockPlatformOrganizationsDataSource? organizationsDataSource,
    this.delay = const Duration(milliseconds: 300),
  }) : dataSource =
           dataSource ??
           MockPlatformDashboardDataSource(
             organizationsDataSource: organizationsDataSource,
           );

  @override
  Future<PlatformDashboardSummary> getPlatformDashboardSummary() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getSummary();
  }

  @override
  Future<List<RecentOrganizationSummary>> getRecentOrganizations() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getRecentOrganizations();
  }
}
