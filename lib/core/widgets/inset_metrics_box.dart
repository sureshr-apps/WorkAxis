import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// One figure in an [InsetMetricsBox]: an icon with its label, then the value.
class InsetMetric {
  const InsetMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

/// Light inset panel that lays [metrics] side by side, split by dividers.
/// Used inside list tiles so every tile shows its key figures the same way.
class InsetMetricsBox extends StatelessWidget {
  const InsetMetricsBox({super.key, required this.metrics});

  final List<InsetMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: AppColors.outlineSubtle.withValues(alpha: 0.6),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              if (i > 0) const VerticalDivider(width: AppSpacing.md),
              Expanded(child: _InsetMetricView(metric: metrics[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsetMetricView extends StatelessWidget {
  const _InsetMetricView({required this.metric});

  final InsetMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(metric.icon, size: 14, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                metric.label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          metric.value,
          style: AppTypography.labelMono.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
