import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/employee_home/presentation/models/correctable_checkout_text.dart';

/// One session with a missing or late check-out and its correction action.
class CheckoutCorrectionTile extends StatelessWidget {
  const CheckoutCorrectionTile({
    super.key,
    required this.entry,
    required this.onRequestCorrection,
  });

  final AttendanceEntry entry;
  final VoidCallback? onRequestCorrection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.kpiBorder),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.shiftDateLabel,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                entry.checkInLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.statusUrgentText,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      entry.checkoutProblemLabel,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusUrgentText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppButton.secondary(
            text: 'Request correction',
            iconData: Icons.edit_calendar_outlined,
            isFullWidth: false,
            onPressed: onRequestCorrection,
          ),
        ],
      ),
    );
  }
}
