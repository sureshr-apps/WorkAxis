import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';
import 'package:workaxis/features/organization_dashboard/presentation/attention_item_presentation.dart';

/// A single exception row inside the "Needs Attention" section.
///
/// When [onAction] is null the action is shown disabled with a
/// "Coming soon" tooltip instead of pretending to work.
class AttentionItemCard extends StatelessWidget {
  const AttentionItemCard({super.key, required this.item, this.onAction});

  final AttentionItem item;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final badgeText = item.badgeText ?? item.statusLabel;
    final actionLabel = item.actionLabel ?? 'Review';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.iconBackground,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Icon(
                  item.itemIcon,
                  size: 18,
                  color: item.iconForeground,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          badgeText,
                          style: AppTypography.labelMono.copyWith(
                            fontWeight: FontWeight.w700,
                            color: item.badgeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      item.details,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Tooltip(
              message: onAction == null ? 'Coming soon' : actionLabel,
              child: AppButton.outlined(
                text: actionLabel,
                iconData: item.actionIcon,
                isFullWidth: false,
                onPressed: onAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
