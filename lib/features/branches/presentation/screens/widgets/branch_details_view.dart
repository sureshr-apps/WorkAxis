import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/geofence_real_map_view.dart';

/// Read-only branch profile, shown on the branch details page. Holds the
/// sections only; the page supplies the navigation, header and kiosk actions.
class BranchDetailsView extends StatelessWidget {
  const BranchDetailsView({
    super.key,
    required this.branch,
    required this.managerNames,
    required this.token,
    required this.error,
  });

  final BranchRecord branch;
  final List<String> managerNames;

  /// Pairing code shown once right after it is generated; never stored.
  final KioskPairingToken? token;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final kioskLabel = token != null
        ? 'Pairing in progress'
        : switch (branch.kioskStatus) {
            KioskPairingStatus.paired => 'Paired',
            KioskPairingStatus.pairingPending => 'Pairing in progress',
            KioskPairingStatus.notPaired => 'Not paired',
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _DetailRow(label: 'Branch code', value: branch.code),
        _DetailRow(label: 'Location', value: branch.location),
        _DetailRow(
          label: 'Status',
          value: branch.isActive ? 'Active' : 'Inactive',
        ),
        _DetailRow(
          label: 'Active employees',
          value: '${branch.activeEmployeeCount}',
        ),
        _DetailRow(
          label: 'Geofence radius',
          value: '${branch.geofenceRadiusMeters} metres',
        ),
        _DetailRow(
          label: 'Coordinates',
          value: branch.hasGeofence
              ? '${branch.latitude}, ${branch.longitude}'
              : 'Geofence not configured',
        ),
        if (branch.hasGeofence) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.kpiBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: GeofenceRealMapView(
              latitude: branch.latitude,
              longitude: branch.longitude,
              geofenceRadiusMeters: branch.geofenceRadiusMeters,
              isWithinGeofence: true,
              branchName: branch.name,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _DetailRow(label: 'Kiosk terminal', value: kioskLabel),
        _DetailRow(
          label: 'Branch managers',
          value: managerNames.isEmpty ? 'Unassigned' : managerNames.join(', '),
        ),
        if (token != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.key_outlined,
                  color: AppColors.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SelectableText(
                    token!.value,
                    style: AppTypography.labelMono.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'This pairing code is shown once and is not stored.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          ErrorBanner(message: error!),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
