import 'package:geolocator/geolocator.dart';
import 'package:workaxis/features/employee_home/domain/models/device_location.dart';
import 'package:workaxis/features/employee_home/domain/services/device_location_gateway.dart';

/// [DeviceLocationGateway] backed by the `geolocator` plugin (Android, iOS
/// and web via `geolocator_web`). Contains no policy; see
/// `GatewayAttendanceLocationProvider` for the permission flow.
class GeolocatorDeviceLocationGateway implements DeviceLocationGateway {
  const GeolocatorDeviceLocationGateway();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermissionState> checkPermission() async =>
      _map(await Geolocator.checkPermission());

  @override
  Future<LocationPermissionState> requestPermission() async =>
      _map(await Geolocator.requestPermission());

  @override
  Future<DeviceLocation> currentFix({required Duration timeout}) async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeout,
      ),
    );
    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );
  }

  static LocationPermissionState _map(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionState.granted;
      case LocationPermission.deniedForever:
        return LocationPermissionState.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationPermissionState.denied;
    }
  }
}
