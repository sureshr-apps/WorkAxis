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

enum AssetAcknowledgementStatus {
  notRequired('Not required'),
  pending('Awaiting acknowledgment'),
  acknowledged('Acknowledged');

  const AssetAcknowledgementStatus(this.label);

  final String label;

  static AssetAcknowledgementStatus fromValue(Object? value) => switch (value) {
    null || 'not_required' => AssetAcknowledgementStatus.notRequired,
    'pending' => AssetAcknowledgementStatus.pending,
    'acknowledged' => AssetAcknowledgementStatus.acknowledged,
    _ => throw FormatException('Unknown asset acknowledgement status: $value'),
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
    this.acknowledgementRequired = false,
    this.acknowledgementStatus = AssetAcknowledgementStatus.notRequired,
    this.assignedByUid,
    this.assignedByName,
    this.assignedAt,
    this.acknowledgedByUid,
    this.acknowledgedByName,
    this.acknowledgedAt,
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
  final bool acknowledgementRequired;
  final AssetAcknowledgementStatus acknowledgementStatus;
  final String? assignedByUid;
  final String? assignedByName;
  final DateTime? assignedAt;
  final String? acknowledgedByUid;
  final String? acknowledgedByName;
  final DateTime? acknowledgedAt;
  final String? serialNumber;
  final String? notes;

  EmployeeAsset copyWith({
    String? employeeId,
    String? employeeName,
    String? branchId,
    String? branchName,
    AssetStatus? status,
    bool? acknowledgementRequired,
    AssetAcknowledgementStatus? acknowledgementStatus,
    String? assignedByUid,
    String? assignedByName,
    DateTime? assignedAt,
    String? acknowledgedByUid,
    String? acknowledgedByName,
    DateTime? acknowledgedAt,
    bool clearAcknowledgementDetails = false,
  }) => EmployeeAsset(
    id: id,
    organizationId: organizationId,
    branchId: branchId ?? this.branchId,
    branchName: branchName ?? this.branchName,
    employeeId: employeeId ?? this.employeeId,
    employeeName: employeeName ?? this.employeeName,
    name: name,
    category: category,
    assetTag: assetTag,
    status: status ?? this.status,
    acknowledgementRequired:
        acknowledgementRequired ?? this.acknowledgementRequired,
    acknowledgementStatus: acknowledgementStatus ?? this.acknowledgementStatus,
    assignedByUid: assignedByUid ?? this.assignedByUid,
    assignedByName: assignedByName ?? this.assignedByName,
    assignedAt: assignedAt ?? this.assignedAt,
    acknowledgedByUid: clearAcknowledgementDetails
        ? null
        : acknowledgedByUid ?? this.acknowledgedByUid,
    acknowledgedByName: clearAcknowledgementDetails
        ? null
        : acknowledgedByName ?? this.acknowledgedByName,
    acknowledgedAt: clearAcknowledgementDetails
        ? null
        : acknowledgedAt ?? this.acknowledgedAt,
    serialNumber: serialNumber,
    notes: notes,
  );
}
