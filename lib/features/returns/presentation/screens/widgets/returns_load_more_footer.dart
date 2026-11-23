import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';

/// "Showing n of m" plus a "Load more" button while more returns match,
/// matching the employee directory's paging footer.
class ReturnsLoadMoreFooter extends StatelessWidget {
  const ReturnsLoadMoreFooter({super.key, required this.controller});

  final ReturnsController controller;

  @override
  Widget build(BuildContext context) {
    final actionError = controller.hasMore
        ? controller.actionErrorMessage
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          Text(
            'Showing ${controller.items.length} of ${controller.matchingCount}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (controller.hasMore) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton.outlined(
              text: 'Load more',
              isFullWidth: false,
              isLoading: controller.isLoadingMore,
              onPressed: controller.loadMore,
            ),
          ],
          if (actionError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              actionError,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.statusUrgentText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
