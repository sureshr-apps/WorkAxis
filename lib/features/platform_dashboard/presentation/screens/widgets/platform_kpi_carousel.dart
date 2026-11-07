import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';

/// Platform KPI carousel utilizing the canonical [ResponsiveKpiSection] template.
class PlatformKpiCarousel extends StatelessWidget {
  final PlatformDashboardSummary summary;

  const PlatformKpiCarousel({super.key, required this.summary});

  List<Widget> _buildCards() {
    return [
      AppKpiCard(
        title: 'Total Organizations',
        value: '${summary.totalOrganizations}',
        accentColor: AppColors.primary,
        icon: Icons.domain_outlined,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryContainer,
        iconPosition: AppKpiIconPosition.bottomRight,
      ),
      AppKpiCard(
        title: 'Active Organizations',
        value: '${summary.activeOrganizations}',
        valueColor: AppColors.kpiPositive,
        accentColor: AppColors.kpiPositiveAccent,
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.kpiPositiveAccent,
        iconBgColor: AppColors.kpiPositiveBackground,
        iconPosition: AppKpiIconPosition.bottomRight,
      ),
      AppKpiCard(
        title: 'Suspended Organizations',
        value: '${summary.suspendedOrganizations}',
        accentColor: AppColors.kpiCritical,
        valueColor: AppColors.kpiCritical,
        icon: Icons.pause_circle_outline_rounded,
        iconColor: AppColors.kpiCritical,
        iconBgColor: AppColors.kpiCriticalBackground,
        iconPosition: AppKpiIconPosition.bottomRight,
      ),
      AppKpiCard(
        title: 'Platform Administrators',
        value: '${summary.platformAdminsCount}',
        accentColor: AppColors.kpiLabel,
        icon: Icons.admin_panel_settings_outlined,
        iconColor: AppColors.kpiLabel,
        iconBgColor: AppColors.kpiNeutralBackground,
        iconPosition: AppKpiIconPosition.bottomRight,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveKpiSection(cards: _buildCards(), cardHeight: 96);
  }
}
