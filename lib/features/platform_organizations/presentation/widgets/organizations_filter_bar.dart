import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';

/// Search field and status filter chips for the organizations list.
///
/// Stateless: the [searchController] is owned (and seeded from the
/// controller's current query) by the screen.
class OrganizationsFilterBar extends StatelessWidget {
  const OrganizationsFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.totalCount,
    required this.activeCount,
    required this.suspendedCount,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final OrganizationStatus? statusFilter;
  final ValueChanged<OrganizationStatus?> onStatusFilterChanged;
  final int totalCount;
  final int activeCount;
  final int suspendedCount;

  @override
  Widget build(BuildContext context) {
    final search = AppTextField.search(
      controller: searchController,
      hintText: 'Search by name or code (e.g. Apex, ORG-APX)',
      onChanged: onSearchChanged,
    );
    final chips = _FilterChips(
      current: statusFilter,
      onChanged: onStatusFilterChanged,
      totalCount: totalCount,
      activeCount: activeCount,
      suspendedCount: suspendedCount,
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
                  child: chips,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: search),
                const SizedBox(width: AppSpacing.md),
                chips,
              ],
            ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.current,
    required this.onChanged,
    required this.totalCount,
    required this.activeCount,
    required this.suspendedCount,
  });

  final OrganizationStatus? current;
  final ValueChanged<OrganizationStatus?> onChanged;
  final int totalCount;
  final int activeCount;
  final int suspendedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Status:',
          style: AppTypography.labelMedium.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(width: AppSpacing.xs),
        _FilterChip(
          label: 'All ($totalCount)',
          isSelected: current == null,
          onTap: () => onChanged(null),
        ),
        const SizedBox(width: AppSpacing.xs),
        _FilterChip(
          label: 'Active ($activeCount)',
          dotColor: AppColors.statusActive,
          isSelected: current == OrganizationStatus.active,
          onTap: () => onChanged(OrganizationStatus.active),
        ),
        const SizedBox(width: AppSpacing.xs),
        _FilterChip(
          label: 'Suspended ($suspendedCount)',
          dotColor: AppColors.statusUrgent,
          isSelected: current == OrganizationStatus.suspended,
          onTap: () => onChanged(OrganizationStatus.suspended),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final Color? dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? AppColors.onPrimary : AppColors.onSurface;
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
                  if (dotColor != null) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.onPrimary : dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
