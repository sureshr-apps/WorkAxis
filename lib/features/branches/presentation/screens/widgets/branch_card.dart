import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// Branch summary card with view/edit actions.
class BranchCard extends StatelessWidget {
  const BranchCard({
    super.key,
    required this.branch,
    required this.onView,
    required this.onEdit,
  });

  final BranchRecord branch;
  final VoidCallback onView;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isPaired = branch.kioskStatus == KioskPairingStatus.paired;
    final kiosk = switch (branch.kioskStatus) {
      KioskPairingStatus.paired => 'Kiosk paired',
      KioskPairingStatus.pairingPending => 'Pairing in progress',
      KioskPairingStatus.notPaired => 'No kiosk paired',
    };
    final geofence = branch.hasGeofence
        ? '${branch.geofenceRadiusMeters} m geofence'
        : 'Geofence not configured';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineSubtle),
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  branch.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              StatusChip.fromStatus(branch.isActive ? 'Active' : 'Inactive'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${branch.code}  ·  ${branch.location}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.outlineSubtle),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.badge_outlined,
            text: '${branch.activeEmployeeCount} active employees',
            textColor: AppColors.onSurface,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.radar,
                  text: geofence,
                  textColor: AppColors.onSurfaceVariant,
                ),
              ),
              Icon(
                isPaired ? Icons.check_circle : Icons.circle_outlined,
                size: 12,
                color: isPaired ? AppColors.statusActive : AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                kiosk,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton.outlined(
                  text: 'View details',
                  iconData: Icons.visibility_outlined,
                  onPressed: onView,
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton.secondary(
                    text: 'Edit',
                    iconData: Icons.edit_outlined,
                    onPressed: onEdit,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.secondary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(color: textColor),
        ),
      ),
    ],
  );
}
