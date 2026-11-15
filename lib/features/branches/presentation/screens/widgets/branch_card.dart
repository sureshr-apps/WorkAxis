import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

const BoxConstraints _actionTouchTarget = BoxConstraints(
  minWidth: AppSpacing.minTouchTarget,
  minHeight: AppSpacing.minTouchTarget,
);

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
            _MetricsBox(branch: branch),
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

class _MetricsBox extends StatelessWidget {
  const _MetricsBox({required this.branch});

  final BranchRecord branch;

  @override
  Widget build(BuildContext context) {
    final geofence = branch.hasGeofence
        ? '${branch.geofenceRadiusMeters} m'
        : 'Not set';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: AppColors.outlineSubtle.withValues(alpha: 0.6),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Metric(
                icon: Icons.people_outline,
                label: 'Employees',
                value: '${branch.activeEmployeeCount} Active',
              ),
            ),
            const VerticalDivider(width: AppSpacing.md),
            Expanded(
              child: _Metric(
                icon: Icons.radar,
                label: 'Geofence',
                value: geofence,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.labelMono.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          IconButton(
            tooltip: 'Edit ${branch.name}',
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.secondary,
            ),
            constraints: _actionTouchTarget,
            onPressed: onEdit,
          ),
        if (onToggleActive != null)
          IconButton(
            tooltip: isActive
                ? 'Suspend ${branch.name}'
                : 'Reactivate ${branch.name}',
            icon: Icon(
              isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
              size: 18,
              color: AppColors.secondary,
            ),
            constraints: _actionTouchTarget,
            onPressed: onToggleActive,
          ),
        if (onDelete != null)
          IconButton(
            tooltip: 'Delete ${branch.name}',
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.statusUrgentText,
            ),
            constraints: _actionTouchTarget,
            onPressed: onDelete,
          ),
      ],
    );
  }
}
