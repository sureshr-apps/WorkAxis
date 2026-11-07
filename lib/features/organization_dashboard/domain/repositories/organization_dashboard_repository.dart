import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';

/// Stable repository contract for Organization Admin Overview.
abstract interface class OrganizationDashboardRepository {
  /// Dashboard metrics for the organization in [access]. Only Organization
  /// Admins may load it; the organization is always derived from [access].
  Future<OrganizationDashboardSummary> getOrganizationDashboardSummary({
    required UserAccessContext access,
  });
}
