import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';

/// One row of the key-branch adherence snapshot.
class BranchAdherenceRow extends StatelessWidget {
  const BranchAdherenceRow({
    super.key,
    required this.snapshot,
    this.showBar = true,
  });

  final BranchAdherenceSnapshot snapshot;
  final bool showBar;

  @override
  Widget build(BuildContext context) {
    final onTarget = snapshot.isOnTarget;
    final badgeBg = onTarget
        ? AppColors.statusActiveContainer
        : AppColors.statusPendingContainer;
    final badgeText = onTarget
        ? AppColors.statusActiveText
        : AppColors.statusPendingText;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Text(
              snapshot.code,
              style: AppTypography.labelMono.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              overflow: TextOverflow.clip,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  snapshot.details,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (showBar) ...[
            Container(
              width: 72,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: AppSpacing.roundedPill,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: snapshot.adherenceRate.clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: onTarget
                        ? AppColors.statusActive
                        : AppColors.statusPending,
                    borderRadius: AppSpacing.roundedPill,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: AppSpacing.roundedXs,
            ),
            child: Text(
              snapshot.adherencePercentage,
              style: AppTypography.labelMono.copyWith(
                fontWeight: FontWeight.w600,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
