import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// Breadcrumb "← [backLabel] / [currentLabel]" shown above form screens.
///
/// The back target is a text link with a 48dp touch height, so it reads as
/// navigation back to the list the form belongs to.
class PageBreadcrumb extends StatelessWidget {
  const PageBreadcrumb({
    super.key,
    required this.backLabel,
    required this.currentLabel,
    required this.onBack,
  });

  final String backLabel;
  final String currentLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Long names (e.g. an organization) shorten rather than overflow the row.
        Flexible(
          child: Semantics(
            button: true,
            label: 'Back to $backLabel',
            child: InkWell(
              onTap: onBack,
              borderRadius: AppSpacing.roundedXs,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        backLabel,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '/',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.outlineVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            currentLabel,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
