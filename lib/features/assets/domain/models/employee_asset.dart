enum AssetStatus {
  assigned('Assigned'),
  maintenance('Needs maintenance'),
  returned('Returned');

  const AssetStatus(this.label);

  final String label;

  static AssetStatus fromValue(Object? value) => switch (value) {
    'assigned' => AssetStatus.assigned,
    'maintenance' => AssetStatus.maintenance,
    'returned' => AssetStatus.returned,
    _ => throw FormatException('Unknown asset status: $value'),
  };
}

/// An organization asset assigned to an employee at one branch.
class EmployeeAsset {
  const EmployeeAsset({
    required this.id,
    required this.organizationId,
    required this.branchId,
    required this.branchName,
    required this.employeeId,
    required this.employeeName,
    required this.name,
    required this.category,
    required this.assetTag,
    required this.status,
    this.serialNumber,
    this.notes,
  });

  /// Empty for a new asset; populated by the repository after saving.
  final String id;
  final String organizationId;
  final String branchId;
  final String branchName;
  final String employeeId;
  final String employeeName;
  final String name;
  final String category;
  final String assetTag;
  final AssetStatus status;
  final String? serialNumber;
  final String? notes;
}
