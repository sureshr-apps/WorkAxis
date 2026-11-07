/// A GPS fix sent with an attendance punch. The server validates it against
/// the branch geofence; the client never decides whether it is "inside".
class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
}
