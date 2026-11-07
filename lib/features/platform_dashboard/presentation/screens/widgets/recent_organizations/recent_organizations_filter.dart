import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';

/// Status filter applied to the recent organizations panel.
enum RecentOrganizationsFilter {
  all('All'),
  active('Active'),
  suspended('Suspended');

  const RecentOrganizationsFilter(this.label);

  final String label;

  bool matches(RecentOrganizationSummary org) => switch (this) {
    RecentOrganizationsFilter.all => true,
    RecentOrganizationsFilter.active => org.isActive,
    RecentOrganizationsFilter.suspended => !org.isActive,
  };
}

/// Filters [organizations] by [filter] and a name/code [query].
List<RecentOrganizationSummary> filterRecentOrganizations(
  List<RecentOrganizationSummary> organizations, {
  required RecentOrganizationsFilter filter,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  return organizations
      .where((org) {
        if (!filter.matches(org)) return false;
        if (q.isEmpty) return true;
        return org.name.toLowerCase().contains(q) ||
            org.code.toLowerCase().contains(q);
      })
      .toList(growable: false);
}
