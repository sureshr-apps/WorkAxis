/// Typed summary for an organization item shown in the Platform Overview.
class RecentOrganizationSummary {
  final String id;
  final String name;
  final String code;

  /// Contact email of the organization's admin, or null when not available.
  final String? adminEmail;
  final String status; // 'active', 'suspended'
  final int branchCount;
  final int employeeCount;
  final DateTime createdAt;

  const RecentOrganizationSummary({
    required this.id,
    required this.name,
    required this.code,
    this.adminEmail,
    required this.status,
    required this.branchCount,
    required this.employeeCount,
    required this.createdAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
}
