import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/employee_home/presentation/models/checkout_notice.dart';

/// Inline check-out reminder in the hero card: amber once the shift has
/// ended, crimson when the check-out is overdue. Icon and title carry the
/// meaning as well as the colour.
class CheckoutNoticeBanner extends StatelessWidget {
  const CheckoutNoticeBanner({super.key, required this.notice});

  final CheckoutNotice notice;

  @override
  Widget build(BuildContext context) {
    final overdue = notice.isOverdue;
    final foreground = overdue
        ? AppColors.statusUrgentText
        : AppColors.statusPendingText;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: overdue
              ? AppColors.statusUrgentContainer
              : AppColors.statusPendingContainer,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: overdue
                ? AppColors.statusUrgentBorder
                : AppColors.statusPendingBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              overdue ? Icons.warning_amber_rounded : Icons.schedule_outlined,
              size: 20,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    notice.message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
