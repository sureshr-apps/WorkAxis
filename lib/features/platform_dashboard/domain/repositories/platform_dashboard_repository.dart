import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';

/// Stable repository contract for Platform Overview metrics and organizations.
abstract interface class PlatformDashboardRepository {
  /// Fetches platform-wide summary metrics.
  Future<PlatformDashboardSummary> getPlatformDashboardSummary();

  /// Fetches the most recently created customer organizations (newest first).
  Future<List<RecentOrganizationSummary>> getRecentOrganizations();
}
