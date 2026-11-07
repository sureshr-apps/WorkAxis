import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';

/// Search field and status filters for the platform administrators list.
///
/// The search controller is owned by the screen (seeded from
/// [PlatformUsersController.searchQuery]) so the visible text always matches
/// the filter in effect.
class PlatformUsersToolbar extends StatelessWidget {
  const PlatformUsersToolbar({
    super.key,
    required this.controller,
    required this.searchController,
  });

  final PlatformUsersController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final search = AppTextField.search(
      controller: searchController,
      hintText: 'Search name, username, email, or phone',
      onChanged: controller.setSearchQuery,
      onClear: () {
        searchController.clear();
        controller.setSearchQuery('');
      },
    );
    final filters = _StatusFilters(controller: controller);

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
                  child: filters,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: AppSpacing.md),
                filters,
              ],
            ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.controller});

  final PlatformUsersController controller;

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
        _StatusFilterButton(
          label: 'All (${controller.totalCount})',
          selected: controller.statusFilter == null,
          onTap: () => controller.setStatusFilter(null),
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatusFilterButton(
          label: 'Active (${controller.activeCount})',
          dotColor: AppColors.statusActive,
          selected: controller.statusFilter == AccountStatus.active,
          onTap: () => controller.setStatusFilter(AccountStatus.active),
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatusFilterButton(
          label: 'Suspended (${controller.suspendedCount})',
          dotColor: AppColors.statusUrgent,
          selected: controller.statusFilter == AccountStatus.suspended,
          onTap: () => controller.setStatusFilter(AccountStatus.suspended),
        ),
      ],
    );
  }
}

class _StatusFilterButton extends StatelessWidget {
  const _StatusFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.onPrimary : dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                  ],
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
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
