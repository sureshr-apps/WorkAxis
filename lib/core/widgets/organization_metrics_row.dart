import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';

const double _wrapTextScale = 1.15;
const double _wrapBelowScreenWidth = 400;

/// Inset strip showing an organization's hub count, staff count and
/// onboarding date. Shared by the Organizations tab and the dashboard's recent
/// organization cards so both present the same metrics the same way.
class OrganizationMetricsRow extends StatelessWidget {
  const OrganizationMetricsRow({
    super.key,
    required this.hubCount,
    required this.staffCount,
    required this.onboardedOn,
  });

  final int? hubCount;
  final int? staffCount;
  final DateTime onboardedOn;

  @override
  Widget build(BuildContext context) {
    const divider = SizedBox(
      height: 20,
      child: VerticalDivider(width: 1, color: AppColors.outlineSubtle),
    );
    // Large text or a narrow phone cannot fit three metrics on one line, so
    // they wrap (dividers dropped) instead of overflowing. Decided from
    // MediaQuery because callers may sit in an IntrinsicHeight, which cannot
    // host a LayoutBuilder.
    final crowded =
        MediaQuery.textScalerOf(context).scale(1) > _wrapTextScale ||
        MediaQuery.sizeOf(context).width < _wrapBelowScreenWidth;
    final metrics = [
      _Metric(
        value: hubCount?.toString() ?? '—',
        label: 'hubs',
        icon: Icons.storefront_outlined,
      ),
      _Metric(
        value: staffCount?.toString() ?? '—',
        label: 'staff',
        icon: Icons.people_outline,
      ),
      _Metric(
        value: AppFormatters.formatDate(onboardedOn),
        label: 'onboarded',
        icon: Icons.calendar_today_outlined,
        isDate: true,
      ),
    ];
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
      child: crowded
          ? Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: metrics,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [metrics[0], divider, metrics[1], divider, metrics[2]],
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
    this.isDate = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool isDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              value,
              style: isDate
                  ? AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    )
                  : AppTypography.labelMono.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
            ),
          ],
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}
