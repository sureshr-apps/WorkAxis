/// Typed summary metrics for Platform Owner / Administrator overview.
class PlatformDashboardSummary {
  final int totalOrganizations;
  final int activeOrganizations;
  final int suspendedOrganizations;
  final int platformAdminsCount;

  const PlatformDashboardSummary({
    required this.totalOrganizations,
    required this.activeOrganizations,
    required this.suspendedOrganizations,
    required this.platformAdminsCount,
  });
}
