/// Compact summary of a customer organization.
class OrganizationSummary {
  const OrganizationSummary({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
