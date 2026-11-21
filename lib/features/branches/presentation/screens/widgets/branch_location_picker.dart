import 'package:flutter/widgets.dart';
import 'package:workaxis/core/maps/map_location_picker.dart';

/// Branch form adapter for the shared map location picker.
class BranchLocationPicker extends StatelessWidget {
  const BranchLocationPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusMeters,
    required this.onLocationSelected,
    this.branchName = '',
    this.forceFallback = false,
  });

  final double? latitude;
  final double? longitude;
  final int geofenceRadiusMeters;
  final void Function(double latitude, double longitude) onLocationSelected;
  final String branchName;
  final bool forceFallback;

  static const double defaultLatitude = MapLocationPicker.defaultLatitude;
  static const double defaultLongitude = MapLocationPicker.defaultLongitude;

  static bool get isPlatformSupported => MapLocationPicker.isPlatformSupported;

  @override
  Widget build(BuildContext context) => MapLocationPicker(
    latitude: latitude,
    longitude: longitude,
    geofenceRadiusMeters: geofenceRadiusMeters,
    onLocationSelected: onLocationSelected,
    locationLabel: branchName.isEmpty ? 'Branch Location' : branchName,
    selectionHelpText: 'Pan the map and tap anywhere to place the store pin, or drag an existing pin.',
    showGeofencePreview: true,
    forceFallback: forceFallback,
  );
}
