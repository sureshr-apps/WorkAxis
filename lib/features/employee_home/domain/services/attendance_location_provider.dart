import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/employee_home/domain/models/device_location.dart';

/// Source of the device location for attendance punches (permission handling
/// and GPS acquisition live behind this contract, not in widgets).
abstract interface class AttendanceLocationProvider {
  /// Current device location. Throws an `AppException` with a user-safe
  /// message when permission is denied or no fix can be obtained.
  Future<DeviceLocation> currentLocation();
}

/// Used until a device-location implementation is wired in (it needs a
/// geolocation package, which the project has not adopted yet). Punches fail
/// with a clear message instead of sending a fabricated position.
class UnavailableAttendanceLocationProvider
    implements AttendanceLocationProvider {
  const UnavailableAttendanceLocationProvider();

  @override
  Future<DeviceLocation> currentLocation() async {
    throw const DatabaseException(
      'No device location provider is configured.',
      userMessage:
          'Location services are not available in this build, so attendance '
          'cannot be recorded yet.',
    );
  }
}
