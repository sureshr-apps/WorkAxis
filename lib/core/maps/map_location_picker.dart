// Source: Google Maps Platform Code Assist
// Internal usage attribution ID: gmp_git_agentskills_v1

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/maps/map_rendering_scope.dart';
import 'package:workaxis/core/maps/geofence_map_painter.dart';

/// Interactive map picker for selecting a point, optionally with a geofence.
class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onLocationSelected,
    this.geofenceRadiusMeters,
    this.locationLabel = 'Selected location',
    this.selectionTitle = 'Select location on map',
    this.selectionHelpText = 'Pan the map and tap anywhere to place the pin, or drag the existing pin.',
    this.showGeofencePreview = false,
    this.forceFallback = false,
  });

  final double? latitude;
  final double? longitude;
  final int? geofenceRadiusMeters;
  final void Function(double latitude, double longitude) onLocationSelected;
  final String locationLabel;
  final String selectionTitle;
  final String selectionHelpText;
  final bool showGeofencePreview;
  final bool forceFallback;

  static const double defaultLatitude = 12.9716;
  static const double defaultLongitude = 77.5946;

  static bool get isPlatformSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  bool _isLocating = false;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    try {
      final p = await Geolocator.checkPermission();
      if (p == LocationPermission.always ||
          p == LocationPermission.whileInUse) {
        if (mounted) setState(() => _hasLocationPermission = true);
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant MapLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != null &&
        widget.longitude != null &&
        (widget.latitude != oldWidget.latitude ||
            widget.longitude != oldWidget.longitude)) {
      _animateTo(widget.latitude!, widget.longitude!);
    }
  }

  void _animateTo(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 16.0),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to detect position.',
              ),
            ),
          );
        }
        return;
      }
      setState(() => _hasLocationPermission = true);
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      widget.onLocationSelected(pos.latitude, pos.longitude);
      _animateTo(pos.latitude, pos.longitude);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not acquire current GPS location.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCoords = widget.latitude != null && widget.longitude != null;
    final centerLat = widget.latitude ?? MapLocationPicker.defaultLatitude;
    final centerLng = widget.longitude ?? MapLocationPicker.defaultLongitude;
    final center = LatLng(centerLat, centerLng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      widget.selectionTitle,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _isLocating ? null : _useCurrentLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 16),
              label: const Text('My location'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                textStyle: AppTypography.labelSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          widget.selectionHelpText,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 210,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.kpiBorder),
            color: AppColors.outlineVariant,
          ),
          clipBehavior: Clip.antiAlias,
          child:
              widget.forceFallback ||
                  MapRenderingScope.useFallbackOf(context) ||
                  !MapLocationPicker.isPlatformSupported
              ? _FallbackPickerView(
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                  radiusMeters: widget.geofenceRadiusMeters,
                  showGeofencePreview: widget.showGeofencePreview,
                  onSelect: widget.onLocationSelected,
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: center,
                    zoom: hasCoords ? 16.0 : 12.0,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (latLng) => widget.onLocationSelected(
                    latLng.latitude,
                    latLng.longitude,
                  ),
                  // Enable gesture recognition inside scrollable dialog
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                  myLocationEnabled: _hasLocationPermission,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  mapType: MapType.normal,
                  circles:
                      hasCoords &&
                          widget.showGeofencePreview &&
                          widget.geofenceRadiusMeters != null
                      ? {
                          Circle(
                            circleId: const CircleId('geofence_preview'),
                            center: center,
                            radius: widget.geofenceRadiusMeters!.toDouble(),
                            fillColor: AppColors.primary.withValues(
                              alpha: 0.18,
                            ),
                            strokeColor: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        }
                      : {},
                  markers: hasCoords
                      ? {
                          Marker(
                            markerId: const MarkerId('location_marker'),
                            position: center,
                            draggable: true,
                            onDragEnd: (newPos) => widget.onLocationSelected(
                              newPos.latitude,
                              newPos.longitude,
                            ),
                            infoWindow: InfoWindow(
                              title: widget.locationLabel,
                              snippet:
                                  widget.showGeofencePreview &&
                                      widget.geofenceRadiusMeters != null
                                  ? '${widget.geofenceRadiusMeters}m geofence'
                                  : null,
                            ),
                          ),
                        }
                      : {},
                ),
        ),
      ],
    );
  }
}

class _FallbackPickerView extends StatelessWidget {
  const _FallbackPickerView({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.showGeofencePreview,
    required this.onSelect,
  });

  final double? latitude;
  final double? longitude;
  final int? radiusMeters;
  final bool showGeofencePreview;
  final void Function(double lat, double lng) onSelect;

  @override
  Widget build(BuildContext context) {
    final hasCoords = latitude != null && longitude != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: GeofenceMapPainter()),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.kpiBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasCoords ? Icons.place : Icons.touch_app_outlined,
                      size: 18,
                      color: hasCoords
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      hasCoords
                          ? '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}'
                                '${showGeofencePreview && radiusMeters != null ? ' (${radiusMeters}m)' : ''}'
                          : 'No location selected',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  key: const Key('test_select_location_btn'),
                  onPressed: () => onSelect(
                    MapLocationPicker.defaultLatitude,
                    MapLocationPicker.defaultLongitude,
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                  child: const Text('Set default coordinates on map'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
