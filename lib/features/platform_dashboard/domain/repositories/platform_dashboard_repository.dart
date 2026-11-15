import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';

/// Stable repository contract for Platform Overview metrics and organizations.
abstract interface class PlatformDashboardRepository {
  /// Fetches platform-wide summary metrics.
  Future<PlatformDashboardSummary> getPlatformDashboardSummary();

  /// Fetches the most recently created customer organizations, in the order the
  /// organizations list returns them (newest first on the server), with the
  /// same fields and counts the Organizations tab shows. [query] and
  /// [status] filter on the server, exactly as the Organizations tab does.
  Future<List<CustomerOrganization>> getRecentOrganizations({
    String? query,
    OrganizationStatus? status,
  });
}
