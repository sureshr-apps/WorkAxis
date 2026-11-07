import 'package:workaxis/features/employee_home/domain/models/device_location.dart';

/// Result of checking or requesting location permission.
enum LocationPermissionState { granted, denied, deniedForever }

/// Tiny seam over a platform geolocation plugin, so permission and timeout
/// handling in [GatewayAttendanceLocationProvider] is unit-testable with a
/// fake and the plugin stays an implementation detail of the data layer.
abstract interface class DeviceLocationGateway {
  Future<bool> isServiceEnabled();

  Future<LocationPermissionState> checkPermission();

  Future<LocationPermissionState> requestPermission();

  /// A fresh high-accuracy fix. May throw `TimeoutException` when no fix
  /// arrives within [timeout].
  Future<DeviceLocation> currentFix({required Duration timeout});
}
