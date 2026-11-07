import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/recent_organizations/recent_organizations_filter.dart';

/// Search field and status chips above the recent organizations table.
class RecentOrganizationsFilterBar extends StatelessWidget {
  const RecentOrganizationsFilterBar({
    super.key,
    required this.isCompact,
    required this.searchController,
    required this.selected,
    required this.counts,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onFilterChanged,
  });

  final bool isCompact;
  final TextEditingController searchController;
  final RecentOrganizationsFilter selected;
  final Map<RecentOrganizationsFilter, int> counts;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<RecentOrganizationsFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final search = AppTextField.search(
      controller: searchController,
      hintText: 'Search recent organizations...',
      onChanged: onSearchChanged,
      onClear: onSearchCleared,
    );
    final chips = [
      for (final filter in RecentOrganizationsFilter.values)
        _FilterChip(
          label: '${filter.label} (${counts[filter] ?? 0})',
          selected: filter == selected,
          onTap: () => onFilterChanged(filter),
        ),
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: AppSpacing.sm, children: chips),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: AppSpacing.md),
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          chips[i],
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedPill,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                borderRadius: AppSpacing.roundedPill,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.outlineSubtle,
                ),
              ),
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.onPrimary : AppColors.secondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
