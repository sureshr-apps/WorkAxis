import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/features/reports/domain/models/report_date_range.dart';
import 'package:workaxis/features/reports/domain/models/report_period.dart';

/// Horizontally scrollable chips for choosing the reporting period.
class ReportPeriodSelector extends StatelessWidget {
  const ReportPeriodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onCustomRangeSelected,
    this.selectedDateRange,
  });

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onSelected;
  final VoidCallback onCustomRangeSelected;
  final ReportDateRange? selectedDateRange;

  String get _customRangeLabel {
    final range = selectedDateRange;
    if (range == null) return ReportPeriod.customRange.label;
    return '${AppFormatters.formatDate(range.startDate)} – '
        '${AppFormatters.formatDate(range.endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final period in ReportPeriod.values.where(
            (period) => period != ReportPeriod.customRange,
          ))
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
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(
                _customRangeLabel,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: selected == ReportPeriod.customRange
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: selected == ReportPeriod.customRange
                      ? AppColors.onPrimary
                      : AppColors.onSurface,
                ),
              ),
              selected: selected == ReportPeriod.customRange,
              onSelected: (_) => onCustomRangeSelected(),
              checkmarkColor: AppColors.onPrimary,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerLowest,
              side: BorderSide(
                color: selected == ReportPeriod.customRange
                    ? AppColors.primary
                    : AppColors.outlineSubtle,
              ),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
            ),
          ),
        ],
      ),
    );
  }
}
