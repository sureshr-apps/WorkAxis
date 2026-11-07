import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';

/// Organization KPI section built with the canonical [ResponsiveKpiSection]
/// and [AppKpiCard] templates.
class OrgKpiCarousel extends StatelessWidget {
  const OrgKpiCarousel({super.key, required this.summary});

  final OrganizationDashboardSummary summary;

  List<Widget> _buildCards() {
    final att = summary.attendance;

    return [
      AppKpiCard(
        title: 'Present Today',
        value: '${att.present}',
        accentColor: AppColors.kpiPositiveAccent,
        icon: Icons.how_to_reg_outlined,
        iconColor: AppColors.kpiPositiveAccent,
        iconBgColor: AppColors.kpiPositiveBackground,
      ),
      AppKpiCard(
        title: 'Absent Today',
        value: '${att.absent}',
        valueColor: att.absent > 0 ? AppColors.kpiCritical : null,
        accentColor: AppColors.kpiCritical,
        icon: Icons.person_off_outlined,
        iconColor: AppColors.kpiCritical,
        iconBgColor: AppColors.kpiCriticalBackground,
      ),
      AppKpiCard(
        title: 'Pending Returns',
        value: '${summary.pendingReturns}',
        valueColor: summary.pendingReturns > 0
            ? AppColors.statusPendingText
            : null,
        accentColor: AppColors.statusPendingText,
        icon: Icons.assignment_late_outlined,
        iconColor: AppColors.statusPendingText,
        iconBgColor: AppColors.statusPendingContainer,
      ),
      AppKpiCard(
        title: 'Total Staff',
        value: '${summary.totalStaff}',
        accentColor: AppColors.primary,
        icon: Icons.badge_outlined,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryContainer,
      ),
      AppKpiCard(
        title: 'Total Branches',
        value: '${summary.totalBranches}',
        accentColor: AppColors.secondary,
        icon: Icons.domain_outlined,
        iconColor: AppColors.secondary,
        iconBgColor: AppColors.secondaryContainer,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveKpiSection(cards: _buildCards(), cardHeight: 96);
  }
}
