import 'dart:async';

import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/employee_home/domain/models/device_location.dart';
import 'package:workaxis/features/employee_home/domain/services/attendance_location_provider.dart';
import 'package:workaxis/features/employee_home/domain/services/device_location_gateway.dart';

/// [AttendanceLocationProvider] that applies the permission flow
/// (service on, permission requested once when denied, blocked state) over a
/// [DeviceLocationGateway] and maps every failure to a [LocationException]
/// with a user-safe message. It never returns a fabricated position.
class GatewayAttendanceLocationProvider implements AttendanceLocationProvider {
  GatewayAttendanceLocationProvider(
    this._gateway, {
    this.timeout = const Duration(seconds: 15),
  });

  final DeviceLocationGateway _gateway;
  final Duration timeout;

  @override
  Future<DeviceLocation> currentLocation() async {
    if (!await _gateway.isServiceEnabled()) {
      throw const LocationException(
        LocationFailure.serviceDisabled,
        'Location services are disabled.',
        userMessage:
            'Location is turned off. Turn on location services to check in.',
      );
    }

    var permission = await _gateway.checkPermission();
    if (permission == LocationPermissionState.denied) {
      permission = await _gateway.requestPermission();
    }
    switch (permission) {
      case LocationPermissionState.granted:
        break;
      case LocationPermissionState.denied:
        throw const LocationException(
          LocationFailure.permissionDenied,
          'Location permission denied.',
          userMessage:
              'Location permission is needed to check in. Allow it and try '
              'again.',
        );
      case LocationPermissionState.deniedForever:
        throw const LocationException(
          LocationFailure.permissionDeniedForever,
          'Location permission permanently denied.',
          userMessage:
              'Location permission is blocked. Enable it for WorkAxis in '
              'your device or browser settings, then try again.',
        );
    }

    try {
      return await _gateway.currentFix(timeout: timeout);
    } on TimeoutException {
      throw const LocationException(
        LocationFailure.timeout,
        'Timed out waiting for a location fix.',
        userMessage:
            'We could not get a GPS fix in time. Move to an open area and try '
            'again.',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw LocationException(
        LocationFailure.unavailable,
        'Location fix failed: ${e.runtimeType}',
        userMessage:
            'We could not read your location. Check location settings and try '
            'again.',
      );
    }
  }
}
