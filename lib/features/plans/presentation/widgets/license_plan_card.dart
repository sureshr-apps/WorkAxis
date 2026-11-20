import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_icon_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/presentation/widgets/license_plan_accent.dart';

const BoxConstraints _actionTouchTarget = BoxConstraints(
  minWidth: AppSpacing.minTouchTarget,
  minHeight: AppSpacing.minTouchTarget,
);

/// One license plan: identity and status on top, the two capacity limits in an
/// inset box, and the plan code with the row actions in the footer.
class LicensePlanCard extends StatelessWidget {
  const LicensePlanCard({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final LicensePlan plan;
  final FutureOr<void> Function() onEdit;
  final FutureOr<void> Function() onToggleStatus;
  final FutureOr<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('license-plan-card-${plan.id}'),
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
          _Header(plan: plan),
          const SizedBox(height: AppSpacing.sm),
          Text(
            plan.description.isEmpty ? '—' : plan.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          _LimitsBox(plan: plan),
          const SizedBox(height: AppSpacing.xs),
          _Footer(
            plan: plan,
            onEdit: onEdit,
            onToggleStatus: onToggleStatus,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.plan});

  final LicensePlan plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: licensePlanAccentForLevel(plan.level),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            plan.name,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Flexible (not a plain child) so the row gives this group a bounded
        // width; FittedBox then scales the pill and chip down at large text
        // scales instead of pushing the header past the card edge.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LevelPill(level: plan.level),
                const SizedBox(width: AppSpacing.sm),
                StatusChip.fromStatus(
                  plan.status.name.toUpperCase(),
                  width: null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedXs,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Text(
        'Level $level',
        style: AppTypography.labelMono.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _LimitsBox extends StatelessWidget {
  const _LimitsBox({required this.plan});

  final LicensePlan plan;

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
        border: Border.all(
          color: AppColors.outlineSubtle.withValues(alpha: 0.6),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _LimitMetric(
                icon: Icons.business_outlined,
                label: 'Stores',
                value: '${plan.maxStores} Stores',
              ),
            ),
            const VerticalDivider(width: AppSpacing.md),
            Expanded(
              child: _LimitMetric(
                icon: Icons.people_outline,
                label: 'Max Users',
                value: '${plan.maxUsers} Users',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitMetric extends StatelessWidget {
  const _LimitMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

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
    required this.plan,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final LicensePlan plan;
  final FutureOr<void> Function() onEdit;
  final FutureOr<void> Function() onToggleStatus;
  final FutureOr<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = plan.isActive;
    final assignedPlanCannotBeDeactivated =
        isActive && plan.assignedOrganizations > 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            'ID: ${plan.planCode}',
            style: AppTypography.labelMono.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppIconButton(
          tooltip: 'Edit ${plan.name}',
          icon: Icons.edit_outlined,
          color: AppColors.secondary,
          constraints: _actionTouchTarget,
          onPressed: onEdit,
        ),
        AppIconButton(
          tooltip: assignedPlanCannotBeDeactivated
              ? 'Cannot deactivate while organizations use this plan'
              : isActive
              ? 'Deactivate ${plan.name}'
              : 'Activate ${plan.name}',
          icon: isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
          color: isActive ? AppColors.statusUrgentText : AppColors.kpiPositive,
          constraints: _actionTouchTarget,
          onPressed: assignedPlanCannotBeDeactivated ? null : onToggleStatus,
        ),
        AppIconButton(
          tooltip: 'Delete ${plan.name}',
          icon: Icons.delete_outline,
          color: AppColors.statusUrgentText,
          constraints: _actionTouchTarget,
          onPressed: onDelete,
        ),
      ],
    );
  }
}
