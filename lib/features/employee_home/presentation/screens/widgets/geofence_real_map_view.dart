// Source: Google Maps Platform Code Assist
// Internal usage attribution ID: gmp_git_agentskills_v1

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/geofence_map_painter.dart';

/// Real map displaying the branch geofence boundary and pin.
///
/// In compliance with user requirements, map dragging/panning is disabled
/// ([scrollGesturesEnabled: false]) to keep focus fixed on the authorized geofence.
class GeofenceRealMapView extends StatefulWidget {
  const GeofenceRealMapView({
    super.key,
    this.latitude,
    this.longitude,
    this.geofenceRadiusMeters,
    this.isWithinGeofence = true,
    this.branchName,
    this.forceFallback = false,
  });

  /// Geofence centre coordinates. Defaults to Downtown Flagship if omitted.
  final double? latitude;
  final double? longitude;

  /// Radius in meters. Defaults to 150m if not provided.
  final int? geofenceRadiusMeters;

  /// Whether the employee is validated within the geofence perimeter.
  final bool isWithinGeofence;

  /// Optional human-readable branch label for pin metadata.
  final String? branchName;

  /// Test hook to render fallback view without initializing Google Maps platform views.
  final bool forceFallback;

  static const double defaultLatitude = 12.9716;
  static const double defaultLongitude = 77.5946;
  static const int defaultRadiusMeters = 150;

  static bool get isPlatformSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get isHeadlessTest {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  State<GeofenceRealMapView> createState() => _GeofenceRealMapViewState();
}

class _GeofenceRealMapViewState extends State<GeofenceRealMapView> {
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (mounted &&
          (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse)) {
        setState(() => _hasLocationPermission = true);
      }
    } catch (_) {
      // Platform channel unavailable or during headless tests.
    }
  }

  double _computeZoom(int radiusMeters) {
    if (radiusMeters <= 100) return 17.0;
    if (radiusMeters <= 250) return 16.0;
    if (radiusMeters <= 500) return 15.0;
    if (radiusMeters <= 1000) return 14.0;
    return 13.0;
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.latitude ?? GeofenceRealMapView.defaultLatitude;
    final lng = widget.longitude ?? GeofenceRealMapView.defaultLongitude;
    final radius =
        widget.geofenceRadiusMeters ?? GeofenceRealMapView.defaultRadiusMeters;
    final center = LatLng(lat, lng);

    // Provide a reliable rendering fallback on Windows desktop or headless tests
    // where Google Maps platform views are not available.
    if (widget.forceFallback ||
        GeofenceRealMapView.isHeadlessTest ||
        !GeofenceRealMapView.isPlatformSupported) {
      return _FallbackMapView(
        latitude: lat,
        longitude: lng,
        radiusMeters: radius,
        isWithinGeofence: widget.isWithinGeofence,
        branchName: widget.branchName,
      );
    }

    final fenceColor = widget.isWithinGeofence
        ? AppColors.primary
        : AppColors.error;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: _computeZoom(radius),
      ),
      // Disallow dragging/panning per requirement
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
      myLocationEnabled: _hasLocationPermission,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      mapType: MapType.normal,
      circles: {
        Circle(
          circleId: const CircleId('geofence_perimeter'),
          center: center,
          radius: radius.toDouble(),
          fillColor: fenceColor.withValues(alpha: 0.18),
          strokeColor: fenceColor,
          strokeWidth: 2,
        ),
      },
      markers: {
        Marker(
          markerId: const MarkerId('branch_center'),
          position: center,
          infoWindow: InfoWindow(
            title: widget.branchName ?? 'Branch Geofence',
            snippet: '${radius}m perimeter',
          ),
        ),
      },
    );
  }
}

class _FallbackMapView extends StatelessWidget {
  const _FallbackMapView({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isWithinGeofence,
    this.branchName,
  });

  final double latitude;
  final double longitude;
  final int radiusMeters;
  final bool isWithinGeofence;
  final String? branchName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: GeofenceMapPainter()),
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
              borderRadius: AppSpacing.roundedXs,
              border: Border.all(color: AppColors.kpiBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)} (${radiusMeters}m)',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
