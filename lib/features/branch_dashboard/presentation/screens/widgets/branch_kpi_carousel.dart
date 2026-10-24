import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';

/// Horizontally swipeable branch-scoped KPI carousel on mobile;
/// adaptive horizontal row/grid on tablet and desktop.
/// Built with the canonical [ResponsiveKpiSection] and [AppKpiCard] templates.
class BranchKpiCarousel extends StatelessWidget {
  final BranchDashboardSummary summary;

  const BranchKpiCarousel({super.key, required this.summary});

  List<Widget> _buildKpiCards() {
    final att = summary.attendance;
    return [
      AppKpiCard(
        title: 'Present Today',
        value: '${att.present}',
        accentColor: const Color(0xFF16A34A),
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF16A34A),
        iconBgColor: const Color(0xFFDCFCE7),
      ),
      AppKpiCard(
        title: 'Absent Today',
        value: '${att.absent}',
        valueColor: att.absent > 0
            ? const Color(0xFFDC2626)
            : AppColors.onSurface,
        accentColor: const Color(0xFFDC2626),
        icon: Icons.person_off_outlined,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEE2E2),
      ),
      AppKpiCard(
        title: 'Attendance %',
        value: '${att.attendancePercentage}%',
        accentColor: AppColors.primary,
        icon: Icons.percent,
        iconColor: AppColors.primary,
        iconBgColor: const Color(0xFFEDF2FE),
      ),
      AppKpiCard(
        title: 'Pending Returns',
        value: '${summary.pendingReturns}',
        valueColor: summary.pendingReturns > 0
            ? const Color(0xFFD97706)
            : AppColors.onSurface,
        accentColor: const Color(0xFFD97706),
        icon: Icons.assignment_late_outlined,
        iconColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFEF3C7),
      ),
      AppKpiCard(
        title: 'Total Employees',
        value: '${summary.totalEmployees}',
        accentColor: const Color(0xFF0284C7),
        icon: Icons.badge_outlined,
        iconColor: const Color(0xFF0284C7),
        iconBgColor: const Color(0xFFE0F2FE),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveKpiSection(cards: _buildKpiCards(), cardHeight: 96);
  }
}
