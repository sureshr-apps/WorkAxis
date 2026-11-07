import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';

/// Prominently yet compactly displays the active branch context,
/// including a "Change Branch" action for managers with multiple assigned branches.
class BranchHeaderBanner extends StatelessWidget {
  const BranchHeaderBanner({super.key, required this.activeBranch});

  final ActiveBranchContext activeBranch;

  @override
  Widget build(BuildContext context) {
    final hasMultipleBranches =
        context
            .watch<AccessController>()
            .accessContext
            ?.hasMultipleAssignedBranches ??
        false;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          _BranchIdentity(activeBranch: activeBranch),
          if (hasMultipleBranches)
            AppButton.outlined(
              text: 'Change Branch',
              iconData: Icons.swap_horiz,
              isFullWidth: false,
              onPressed: () => context.go(AppRoutes.selectBranch),
            ),
        ],
      ),
    );
  }
}

class _BranchIdentity extends StatelessWidget {
  const _BranchIdentity({required this.activeBranch});

  final ActiveBranchContext activeBranch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: AppSpacing.roundedSm,
          ),
          child: const Icon(
            Icons.storefront,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      activeBranch.branchName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs + 2,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Text(
                      activeBranch.branchCode,
                      style: AppTypography.labelMono.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Active Branch Operational Scope',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
