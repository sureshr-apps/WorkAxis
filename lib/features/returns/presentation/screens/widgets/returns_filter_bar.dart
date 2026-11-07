import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/content_width_scope.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';

/// Search field plus status filter chips shared by the returns screens.
class ReturnsFilterBar extends StatelessWidget {
  const ReturnsFilterBar({
    super.key,
    required this.controller,
    required this.searchController,
    required this.searchHint,
  });

  final ReturnsController controller;

  /// Owned by the screen and seeded from [ReturnsController.searchQuery].
  final TextEditingController searchController;
  final String searchHint;

  @override
  Widget build(BuildContext context) {
    final isCompact = ContentWidthScope.of(context) < AppBreakpoints.mediumMin;

    final searchField = AppTextField.search(
      controller: searchController,
      hintText: searchHint,
      onChanged: controller.setSearchQuery,
    );

    final statusChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusFilterChip(
            label: 'All (${controller.totalCount})',
            isSelected: controller.statusFilter == null,
            onSelected: () => controller.setFilter(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          for (final status in ReturnStatus.values) ...[
            _StatusFilterChip(
              label: '${status.label} (${_countFor(status)})',
              isSelected: controller.statusFilter == status,
              onSelected: () => controller.setFilter(status),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: AppSpacing.sm),
          statusChips,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: AppSpacing.md),
        statusChips,
      ],
    );
  }

  int _countFor(ReturnStatus status) => switch (status) {
    ReturnStatus.pending => controller.pendingCount,
    ReturnStatus.approved => controller.approvedCount,
    ReturnStatus.rejected => controller.rejectedCount,
  };
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      checkmarkColor: AppColors.onPrimary,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerLowest,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.outlineSubtle,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
    );
  }
}
