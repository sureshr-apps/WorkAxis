import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// A titled list of pending exception tiles with a compact empty message.
class ExceptionReviewList extends StatelessWidget {
  const ExceptionReviewList({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '$title (${children.length})',
        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSpacing.sm),
      if (children.isEmpty)
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppColors.statusActiveText,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                emptyMessage,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        )
      else
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          children[i],
        ],
    ],
  );
}
