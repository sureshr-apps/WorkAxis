import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/reports/domain/models/report_period.dart';

/// Horizontally scrollable chips for choosing the reporting period.
class ReportPeriodSelector extends StatelessWidget {
  const ReportPeriodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final period in ReportPeriod.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(
                  period.label,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: selected == period
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected == period
                        ? AppColors.onPrimary
                        : AppColors.onSurface,
                  ),
                ),
                selected: selected == period,
                onSelected: (_) => onSelected(period),
                checkmarkColor: AppColors.onPrimary,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceContainerLowest,
                side: BorderSide(
                  color: selected == period
                      ? AppColors.primary
                      : AppColors.outlineSubtle,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedSm,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
