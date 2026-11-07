/// Compact summary of a customer organization.
class OrganizationSummary {
  const OrganizationSummary({
    required this.id,
    required this.name,
    required this.code,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String code;

  /// False when the organization is suspended; its users are denied access.
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
