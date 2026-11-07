import 'package:workaxis/core/errors/validation_exception.dart';

/// Geofence rules shared by the mock and production branch repositories.
///
/// The radius range is the stricter of the server (10-5000 m) and the app
/// (25 m minimum): 25-5000 m. Coordinates are either both set or both unset
/// (geofence not configured); (0, 0) is rejected as a placeholder.
class BranchGeofenceValidator {
  BranchGeofenceValidator._();

  static const int minRadiusMeters = 25;
  static const int maxRadiusMeters = 5000;
  static const int defaultRadiusMeters = 100;

  /// Throws [ValidationException] on invalid input.
  static void validate({
    required double? latitude,
    required double? longitude,
    required int radiusMeters,
  }) {
    if (radiusMeters < minRadiusMeters || radiusMeters > maxRadiusMeters) {
      throw ValidationException(
        'Geofence radius must be between $minRadiusMeters and '
        '$maxRadiusMeters meters.',
      );
    }
    if (latitude == null && longitude == null) return;
    if (latitude == null || longitude == null) {
      throw ValidationException(
        'Enter both latitude and longitude, or leave both empty.',
      );
    }
    if (latitude.isNaN || longitude.isNaN) {
      throw ValidationException('Enter valid geofence coordinates.');
    }
    if (latitude < -90 || latitude > 90) {
      throw ValidationException('Latitude must be between -90 and 90.');
    }
    if (longitude < -180 || longitude > 180) {
      throw ValidationException('Longitude must be between -180 and 180.');
    }
    if (latitude == 0 && longitude == 0) {
      throw ValidationException(
        'Coordinates 0, 0 are not a real location. Set the branch location.',
      );
    }
  }
}
