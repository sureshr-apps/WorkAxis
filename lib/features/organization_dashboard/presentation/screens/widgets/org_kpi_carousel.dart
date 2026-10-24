import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';

/// Organization KPI carousel utilizing canonical [ResponsiveKpiSection] and [AppKpiCard].
class OrgKpiCarousel extends StatelessWidget {
  final OrganizationDashboardSummary summary;

  const OrgKpiCarousel({super.key, required this.summary});

  List<Widget> _buildCards() {
    final att = summary.attendance;

    return [
      // Card 1: Present Today
      AppKpiCard(
        title: 'Present Today',
        value: '${att.present}',
        accentColor: const Color(0xFF16A34A),
        icon: Icons.how_to_reg_outlined,
        iconColor: const Color(0xFF16A34A),
        iconBgColor: const Color(0xFFDCFCE7),
      ),

      // Card 2: Absent Today
      AppKpiCard(
        title: 'Absent Today',
        value: '${att.absent}',
        valueColor: att.absent > 0 ? const Color(0xFFDC2626) : null,
        accentColor: const Color(0xFFDC2626),
        icon: Icons.person_off_outlined,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEE2E2),
      ),

      // Card 3: Pending Returns
      AppKpiCard(
        title: 'Pending Returns',
        value: '${summary.pendingReturns}',
        valueColor: summary.pendingReturns > 0
            ? const Color(0xFFD97706)
            : null,
        accentColor: const Color(0xFFD97706),
        icon: Icons.assignment_late_outlined,
        iconColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFEF3C7),
      ),

      // Card 4: Total Staff
      AppKpiCard(
        title: 'Total Staff',
        value: '${summary.totalStaff}',
        accentColor: AppColors.primary,
        icon: Icons.badge_outlined,
        iconColor: AppColors.primary,
        iconBgColor: const Color(0xFFEDF2FE),
      ),

      // Card 5: Total Branches
      AppKpiCard(
        title: 'Total Branches',
        value: '${summary.totalBranches}',
        accentColor: const Color(0xFF0284C7),
        icon: Icons.domain_outlined,
        iconColor: const Color(0xFF0284C7),
        iconBgColor: const Color(0xFFE0F2FE),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveKpiSection(cards: _buildCards(), cardHeight: 96);
  }
}

/// Legacy alias for [AppKpiCard] with label property.
class OrgKpiCard extends StatelessWidget {
  final String label;
  final Widget iconBox;
  final String value;
  final Widget? inlineBadge;
  final Widget bottomWidget;

  const OrgKpiCard({
    super.key,
    required this.label,
    required this.iconBox,
    required this.value,
    this.inlineBadge,
    required this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppKpiCard(
      title: label,
      value: value,
      customIconBox: iconBox,
      inlineBadge: inlineBadge,
      bottomWidget: bottomWidget,
    );
  }
}
