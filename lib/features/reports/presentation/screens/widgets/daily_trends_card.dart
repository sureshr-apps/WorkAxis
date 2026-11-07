import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/presentation/screens/widgets/report_section_card.dart';

/// Per-day on-time / late / absent compliance bars.
class DailyTrendsCard extends StatelessWidget {
  const DailyTrendsCard({super.key, required this.trends});

  final List<DailyAttendanceMetric> trends;

  @override
  Widget build(BuildContext context) {
    return ReportSectionCard(
      icon: Icons.bar_chart_outlined,
      title: 'Daily Attendance Compliance',
      subtitle: 'On-time punch compliance vs late and missing arrivals',
      child: Column(
        children: [
          if (trends.isEmpty)
            Text(
              'No daily attendance data is available for this period.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            for (final trend in trends) _TrendRow(trend: trend),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _LegendItem(AppColors.statusActive, 'On Time'),
              _LegendItem(AppColors.statusPending, 'Late'),
              _LegendItem(AppColors.statusUrgent, 'Missing / Absent'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.trend});

  final DailyAttendanceMetric trend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              trend.dayName,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: AppSpacing.roundedXs,
              child: SizedBox(
                height: 12,
                child: ColoredBox(
                  color: AppColors.kpiNeutralBackground,
                  child: Row(
                    children: [
                      _segment(trend.onTimePercent, AppColors.statusActive),
                      _segment(trend.latePercent, AppColors.statusPending),
                      _segment(trend.absentPercent, AppColors.statusUrgent),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 48,
            child: Text(
              '${trend.onTimePercent.toInt()}%',
              textAlign: TextAlign.right,
              style: AppTypography.labelMono,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(double percent, Color color) {
    final flex = percent.round();
    if (flex <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: flex,
      child: ColoredBox(color: color),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
