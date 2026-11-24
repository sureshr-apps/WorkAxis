import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';

/// Shared layout of a pending exception: employee and state chip on top,
/// labelled facts in the middle, Approve / Reject at the bottom.
class ExceptionReviewTileFrame extends StatelessWidget {
  const ExceptionReviewTileFrame({
    super.key,
    required this.employeeName,
    required this.chipLabel,
    required this.chipType,
    required this.lines,
    required this.onApprove,
    required this.onReject,
    this.note,
  });

  final String employeeName;
  final String chipLabel;
  final StatusType chipType;
  final List<ExceptionReviewLine> lines;

  /// Free text shown in a quoted box (e.g. the employee's reason).
  final String? note;

  /// Null disables the action (e.g. while another decision is saving).
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: AppSpacing.roundedMd,
      border: Border.all(color: AppColors.outlineSubtle),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                employeeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: StatusChip(label: chipLabel, type: chipType, width: null),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final line in lines) line,
        if (note != null && note!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Text(
              '“${note!}”',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: [
            AppButton.outlined(
              text: 'Reject',
              iconData: Icons.close,
              isFullWidth: false,
              onPressed: onReject,
            ),
            AppButton.secondary(
              text: 'Approve',
              iconData: Icons.check,
              isFullWidth: false,
              onPressed: onApprove,
            ),
          ],
        ),
      ],
    ),
  );
}

/// One labelled fact in an exception tile.
class ExceptionReviewLine extends StatelessWidget {
  const ExceptionReviewLine({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
