/// Summary representation of a branch location.
class BranchSummary {
  const BranchSummary({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    required this.location,
    this.activeEmployeeCount = 0,
    this.isActive = true,
  });

  final String id;
  final String organizationId;
  final String name;
  final String code;
  final String location;
  final int activeEmployeeCount;
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
