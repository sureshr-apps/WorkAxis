import 'package:workaxis/features/access/domain/models/branch_summary.dart';

enum KioskPairingStatus { notPaired, pairingPending, paired }

class BranchManagerOption {
  const BranchManagerOption({required this.id, required this.name});

  final String id;
  final String name;
}

/// Operational branch settings layered on the access directory's branch summary.
class BranchRecord {
  const BranchRecord({
    required this.summary,
    required this.geofenceRadiusMeters,
    required this.managerIds,
    required this.kioskStatus,
    this.latitude,
    this.longitude,
    this.isMainBranch = false,
    this.requestId,
  });

  final BranchSummary summary;
  final String? requestId;
  final int geofenceRadiusMeters;

  /// Null until a geofence centre is configured. Never defaulted: a branch
  /// without coordinates cannot validate attendance punches.
  final double? latitude;
  final double? longitude;
  final bool isMainBranch;
  final List<String> managerIds;
  final KioskPairingStatus kioskStatus;

  String get id => summary.id;
  String get organizationId => summary.organizationId;
  String get name => summary.name;
  String get code => summary.code;
  String get location => summary.location;
  int get activeEmployeeCount => summary.activeEmployeeCount;
  bool get isActive => summary.isActive;

  /// Whether a geofence centre is configured.
  bool get hasGeofence => latitude != null && longitude != null;

  BranchRecord copyWith({
    BranchSummary? summary,
    int? geofenceRadiusMeters,
    List<String>? managerIds,
    KioskPairingStatus? kioskStatus,
    double? latitude,
    double? longitude,
    bool? isMainBranch,
    String? requestId,
  }) => BranchRecord(
    summary: summary ?? this.summary,
    requestId: requestId ?? this.requestId,
    geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
    managerIds: managerIds ?? this.managerIds,
    kioskStatus: kioskStatus ?? this.kioskStatus,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    isMainBranch: isMainBranch ?? this.isMainBranch,
  );
}

class KioskPairingToken {
  const KioskPairingToken({
    required this.branchId,
    required this.value,
    this.expiresAt,
  });

  final String branchId;
  final String value;

  /// When the code stops being valid (server-issued tokens expire).
  final DateTime? expiresAt;
}
