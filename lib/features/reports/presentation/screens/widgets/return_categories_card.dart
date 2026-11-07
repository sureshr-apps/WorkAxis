import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/presentation/screens/widgets/report_section_card.dart';

/// Distribution of return reasons.
class ReturnCategoriesCard extends StatelessWidget {
  const ReturnCategoriesCard({super.key, required this.summary});

  final OperationalReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final scope = summary.returnCountsCoverPeriod
        ? ''
        : ' · all returns to date';
    return ReportSectionCard(
      icon: Icons.pie_chart_outline,
      title: 'Return Reasons & Shrinkage',
      subtitle:
          'Distribution of return causes (${summary.returnVolume} total items$scope)',
      child: Column(
        children: [
          if (summary.returnCategories.isEmpty)
            Text(
              'No returns recorded.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            for (final category in summary.returnCategories)
              _CategoryRow(category: category),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final CategoryReturnMetric category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.categoryName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${category.count} items (${category.percentage}%)',
                style: AppTypography.labelMono,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppSpacing.roundedXs,
            child: LinearProgressIndicator(
              value: category.percentage / 100,
              backgroundColor: AppColors.kpiNeutralBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
