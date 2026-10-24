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
    required this.latitude,
    required this.longitude,
    required this.managerIds,
    required this.kioskStatus,
  });

  final BranchSummary summary;
  final int geofenceRadiusMeters;
  final double latitude;
  final double longitude;
  final List<String> managerIds;
  final KioskPairingStatus kioskStatus;

  String get id => summary.id;
  String get organizationId => summary.organizationId;
  String get name => summary.name;
  String get code => summary.code;
  String get location => summary.location;
  int get activeEmployeeCount => summary.activeEmployeeCount;
  bool get isActive => summary.isActive;
}

class KioskPairingToken {
  const KioskPairingToken({required this.branchId, required this.value});

  final String branchId;
  final String value;
}
