import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// Dismissible error panel with a title, shown above the form sections.
class OrganizationFormErrorBanner extends StatelessWidget {
  const OrganizationFormErrorBanner({
    super.key,
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.statusUrgentContainer,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: AppColors.statusUrgentBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.report_problem_outlined,
              color: AppColors.statusUrgent,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusUrgentText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      message,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.statusUrgentText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              icon: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.statusUrgentText,
              ),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
