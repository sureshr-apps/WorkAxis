import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Search field, status chips and level dropdown for the plan list.
///
/// Stateless: the [searchController] is owned by the screen and seeded from the
/// controller's current query.
class LicensePlansFilterBar extends StatelessWidget {
  const LicensePlansFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.totalCount,
    required this.levels,
    required this.levelFilter,
    required this.onLevelFilterChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final PlanStatus? statusFilter;
  final ValueChanged<PlanStatus?> onStatusFilterChanged;
  final int totalCount;

  /// Levels offered by the dropdown, ascending.
  final List<int> levels;
  final int? levelFilter;
  final ValueChanged<int?> onLevelFilterChanged;

  @override
  Widget build(BuildContext context) {
    final search = AppTextField.search(
      controller: searchController,
      hintText: 'Search plans...',
      onChanged: onSearchChanged,
    );
    final controls = _FilterControls(
      statusFilter: statusFilter,
      onStatusFilterChanged: onStatusFilterChanged,
      totalCount: totalCount,
      levels: levels,
      levelFilter: levelFilter,
      onLevelFilterChanged: onLevelFilterChanged,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      child: context.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: controls,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: AppSpacing.md),
                controls,
              ],
            ),
    );
  }
}

class _FilterControls extends StatelessWidget {
  const _FilterControls({
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.totalCount,
    required this.levels,
    required this.levelFilter,
    required this.onLevelFilterChanged,
  });

  final PlanStatus? statusFilter;
  final ValueChanged<PlanStatus?> onStatusFilterChanged;
  final int totalCount;
  final List<int> levels;
  final int? levelFilter;
  final ValueChanged<int?> onLevelFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusChip(
          label: 'All Statuses',
          badge: '$totalCount',
          isSelected: statusFilter == null,
          onTap: () => onStatusFilterChanged(null),
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatusChip(
          label: 'Active',
          isSelected: statusFilter == PlanStatus.active,
          onTap: () => onStatusFilterChanged(PlanStatus.active),
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatusChip(
          label: 'Inactive',
          isSelected: statusFilter == PlanStatus.inactive,
          onTap: () => onStatusFilterChanged(PlanStatus.inactive),
        ),
        const SizedBox(width: AppSpacing.sm),
        _LevelDropdown(
          levels: levels,
          value: levelFilter,
          onChanged: onLevelFilterChanged,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? AppColors.onPrimary : AppColors.onSurface;
    final badgeBackground = isSelected
        ? AppColors.onPrimary.withValues(alpha: 0.2)
        : AppColors.surfaceContainerHigh;
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedPill,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                borderRadius: AppSpacing.roundedPill,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBackground,
                        borderRadius: AppSpacing.roundedPill,
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelDropdown extends StatelessWidget {
  const _LevelDropdown({
    required this.levels,
    required this.value,
    required this.onChanged,
  });

  final List<int> levels;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    // The selected level stays offered even when the loaded rows no longer
    // contain it, so the dropdown never holds a value it cannot show.
    final options = {...levels, ?value}.toList()..sort();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          isDense: true,
          borderRadius: AppSpacing.roundedSm,
          style: AppTypography.labelMedium.copyWith(color: AppColors.onSurface),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All Levels'),
            ),
            for (final level in options)
              DropdownMenuItem<int?>(value: level, child: Text('Level $level')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
