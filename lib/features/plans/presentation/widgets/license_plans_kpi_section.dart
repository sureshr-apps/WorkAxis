import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_summary.dart';

/// Three summary cards: plan counts, organizations on a license, and the
/// highest visible plan limit.
class LicensePlansKpiSection extends StatelessWidget {
  const LicensePlansKpiSection({
    super.key,
    required this.summary,
    required this.highestPlan,
  });

  final LicensePlanSummary summary;
  final LicensePlan? highestPlan;

  @override
  Widget build(BuildContext context) {
    final highest = highestPlan;
    return ResponsiveKpiSection(
      // Taller than the 96dp default: the phone carousel must fit the
      // footer line ("N Inactive") under the value without overflowing.
      cardHeight: 112,
      cards: [
        AppKpiCard(
          title: 'Total Plans',
          value: '${summary.totalPlans}',
          accentColor: AppColors.primaryDark,
          icon: Icons.tune,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryContainer,
          inlineBadge: AppKpiCard.badge(
            '${summary.activePlans} Active',
            backgroundColor: AppColors.statusActiveContainer,
            textColor: AppColors.statusActiveText,
          ),
          footerText: '${summary.inactivePlans} Inactive',
          footerDotColor: AppColors.statusNeutral,
        ),
        AppKpiCard(
          title: 'Assigned Orgs',
          value: '${summary.assignedOrganizations}',
          accentColor: AppColors.kpiPositiveAccent,
          icon: Icons.storefront_outlined,
          iconColor: AppColors.kpiPositiveAccent,
          iconBgColor: AppColors.kpiPositiveBackground,
          inlineBadge: AppKpiCard.badge('Assigned'),
          footerText: 'Organizations linked',
          footerDotColor: AppColors.primary,
        ),
        AppKpiCard(
          title: 'Highest Plan Limit',
          value: highest == null ? '—' : '${highest.maxStores}',
          total: highest == null ? null : 'Stores',
          accentColor: AppColors.primary,
          icon: Icons.shield_outlined,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryContainer,
          inlineBadge: highest == null
              ? null
              : AppKpiCard.badge('Level ${highest.level}'),
          footerText: highest == null
              ? 'No limits'
              : '${highest.maxUsers} Users · ${highest.name}',
          footerDotColor: AppColors.primary,
        ),
      ],
    );
  }
}
