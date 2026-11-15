import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/card_action_icon.dart';
import 'package:workaxis/core/widgets/inset_metrics_box.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// One branch, laid out like a license plan card: name and status with a chevron
/// on top, the employee and geofence figures in an inset box, and the branch
/// code with the row actions in the footer. The whole card opens the branch.
class BranchCard extends StatelessWidget {
  const BranchCard({
    super.key,
    required this.branch,
    required this.onOpen,
    this.onEdit,
    this.onToggleActive,
    this.onDelete,
  });

  final BranchRecord branch;
  final VoidCallback onOpen;

  /// Management actions; each is shown only when its callback is given.
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        key: Key('branch-card-${branch.id}'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: AppColors.outlineSubtle),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(branch: branch),
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
            InsetMetricsBox(
              metrics: [
                InsetMetric(
                  icon: Icons.people_outline,
                  label: 'Employees',
                  value: '${branch.activeEmployeeCount} Active',
                ),
                InsetMetric(
                  icon: Icons.radar,
                  label: 'Geofence',
                  value: branch.hasGeofence
                      ? '${branch.geofenceRadiusMeters} m'
                      : 'Not set',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _Footer(
              branch: branch,
              onEdit: onEdit,
              onToggleActive: onToggleActive,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.branch});

  final BranchRecord branch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            branch.name,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusChip.fromStatus(
          branch.isActive ? 'Active' : 'Inactive',
          width: 96,
        ),
        const SizedBox(width: AppSpacing.xs),
        const Icon(
          Icons.chevron_right_rounded,
          size: 24,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.branch,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final BranchRecord branch;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = branch.isActive;
    return Row(
      children: [
        Expanded(
          child: Text(
            'ID: ${branch.code}',
            style: AppTypography.labelMono.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onEdit != null)
          CardActionIcon(
            tooltip: 'Edit ${branch.name}',
            icon: Icons.edit_outlined,
            color: AppColors.secondary,
            onPressed: onEdit!,
          ),
        if (onToggleActive != null)
          CardActionIcon(
            tooltip: isActive
                ? 'Suspend ${branch.name}'
                : 'Reactivate ${branch.name}',
            icon: isActive
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            color: AppColors.secondary,
            onPressed: onToggleActive!,
          ),
        if (onDelete != null)
          CardActionIcon(
            tooltip: 'Delete ${branch.name}',
            icon: Icons.delete_outline,
            color: AppColors.statusUrgentText,
            onPressed: onDelete!,
          ),
      ],
    );
  }
}
