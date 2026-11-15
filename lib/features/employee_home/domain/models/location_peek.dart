import 'package:workaxis/features/employee_home/domain/models/device_location.dart';

/// Why a passive (non-prompting) location read did or did not produce a fix.
enum LocationReadiness {
  /// Permission is granted and a fix was read.
  ready,

  /// Device location services are switched off.
  serviceDisabled,

  /// Permission has not been granted yet; asking requires a user action.
  permissionNeeded,

  /// Permission is blocked and can only be changed in system settings.
  permissionBlocked,

  /// Permission is granted but no fix could be read in time.
  unavailable,
}

/// Outcome of reading the location without ever showing a permission prompt.
class LocationPeek {
  const LocationPeek(this.readiness, [this.fix]);

  final LocationReadiness readiness;

  /// Non-null only when [readiness] is [LocationReadiness.ready].
  final DeviceLocation? fix;
}
