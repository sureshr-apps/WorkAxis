import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/geofence_map_painter.dart';

/// Geofence card: location status, a schematic map and the telemetry tiles the
/// backend actually provided. Tiles without data are omitted, never invented.
class ActiveGeofenceCard extends StatelessWidget {
  const ActiveGeofenceCard({super.key, required this.summary});

  final EmployeeHomeSummary summary;

  static bool _has(String value) =>
      value.isNotEmpty && value != EmployeeHomeSummary.unavailable;

  /// "Jordan Lee" -> "J. Lee"; safe for empty and single-word names.
  static String supervisorLabel(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return EmployeeHomeSummary.unavailable;
    if (parts.length == 1) return parts.first;
    return '${parts.first[0]}. ${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <_Tile>[
      if (_has(summary.networkMac)) _Tile('NETWORK MAC', summary.networkMac),
      if (_has(summary.syncRate)) _Tile('SYNC RATE', summary.syncRate),
      if (_has(summary.badgeAuth))
        _Tile('BADGE AUTH', summary.badgeAuth, isSuccess: true),
      if (_has(summary.supervisorName))
        _Tile('SUPERVISOR', supervisorLabel(summary.supervisorName)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.kpiBorder),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: AppSpacing.md),
          _map(),
          if (tiles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _tileGrid(tiles),
          ],
        ],
      ),
    );
  }

  Widget _header() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radar, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Active Geofence Telemetry',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        StatusChip(
          label: summary.isWithinGeofence
              ? 'Inside geofence'
              : 'Outside geofence',
          type: summary.isWithinGeofence
              ? StatusType.active
              : StatusType.urgent,
          width: null,
        ),
      ],
    );
  }

  Widget _map() {
    final hasFence = _has(summary.geofenceId) || _has(summary.geofenceZone);
    return Semantics(
      label: 'Schematic geofence map',
      child: Container(
        height: 176,
        decoration: BoxDecoration(
          borderRadius: AppSpacing.roundedMd,
          color: AppColors.outlineVariant,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: GeofenceMapPainter()),
            if (hasFence)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.onSurface.withValues(alpha: 0.86),
                        AppColors.onSurface.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_has(summary.geofenceId))
                        Text(
                          'GEOFENCE ID: ${summary.geofenceId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMono.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      if (_has(summary.geofenceZone))
                        Text(
                          summary.geofenceZone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tileGrid(List<_Tile> tiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < AppBreakpoints.compactMax - 150
            ? 2
            : tiles.length.clamp(1, 4);
        const gap = AppSpacing.sm;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: _TelemetryTile(tile: tile),
              ),
          ],
        );
      },
    );
  }
}

class _Tile {
  const _Tile(this.label, this.value, {this.isSuccess = false});
  final String label;
  final String value;
  final bool isSuccess;
}

class _TelemetryTile extends StatelessWidget {
  const _TelemetryTile({required this.tile});
  final _Tile tile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.kpiBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tile.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            tile.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: tile.isSuccess
                  ? AppColors.statusActiveText
                  : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
