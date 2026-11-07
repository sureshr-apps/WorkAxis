import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';

/// Branch-scoped KPI section built with the canonical [ResponsiveKpiSection]
/// and [AppKpiCard] templates.
class BranchKpiCarousel extends StatelessWidget {
  const BranchKpiCarousel({super.key, required this.summary});

  final BranchDashboardSummary summary;

  List<Widget> _buildKpiCards() {
    final att = summary.attendance;
    return [
      AppKpiCard(
        title: 'Present Today',
        value: '${att.present}',
        accentColor: AppColors.kpiPositiveAccent,
        icon: Icons.check_circle_outline,
        iconColor: AppColors.kpiPositiveAccent,
        iconBgColor: AppColors.kpiPositiveBackground,
      ),
      AppKpiCard(
        title: 'Absent Today',
        value: '${att.absent}',
        valueColor: att.absent > 0
            ? AppColors.kpiCritical
            : AppColors.onSurface,
        accentColor: AppColors.kpiCritical,
        icon: Icons.person_off_outlined,
        iconColor: AppColors.kpiCritical,
        iconBgColor: AppColors.kpiCriticalBackground,
      ),
      AppKpiCard(
        title: 'Attendance %',
        value: '${att.attendancePercentage}%',
        accentColor: AppColors.primary,
        icon: Icons.percent,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryContainer,
      ),
      AppKpiCard(
        title: 'Pending Returns',
        value: '${summary.pendingReturns}',
        valueColor: summary.pendingReturns > 0
            ? AppColors.statusPendingText
            : AppColors.onSurface,
        accentColor: AppColors.statusPendingText,
        icon: Icons.assignment_late_outlined,
        iconColor: AppColors.statusPendingText,
        iconBgColor: AppColors.statusPendingContainer,
      ),
      AppKpiCard(
        title: 'Total Employees',
        value: '${summary.totalEmployees}',
        accentColor: AppColors.secondary,
        icon: Icons.badge_outlined,
        iconColor: AppColors.secondary,
        iconBgColor: AppColors.secondaryContainer,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveKpiSection(cards: _buildKpiCards(), cardHeight: 96);
  }
}
