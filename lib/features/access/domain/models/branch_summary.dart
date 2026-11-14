/// Summary representation of a branch location.
class BranchSummary {
  const BranchSummary({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    required this.location,
    this.latitude,
    this.longitude,
    this.geofenceRadiusMeters,
    this.activeEmployeeCount = 0,
    this.isActive = true,
  });

  final String id;
  final String organizationId;
  final String name;
  final String code;
  final String location;
  final double? latitude;
  final double? longitude;
  final int? geofenceRadiusMeters;
  final int activeEmployeeCount;
  final bool isActive;

  BranchSummary copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? code,
    String? location,
    double? latitude,
    double? longitude,
    int? geofenceRadiusMeters,
    int? activeEmployeeCount,
    bool? isActive,
  }) => BranchSummary(
    id: id ?? this.id,
    organizationId: organizationId ?? this.organizationId,
    name: name ?? this.name,
    code: code ?? this.code,
    location: location ?? this.location,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
    activeEmployeeCount: activeEmployeeCount ?? this.activeEmployeeCount,
    isActive: isActive ?? this.isActive,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
