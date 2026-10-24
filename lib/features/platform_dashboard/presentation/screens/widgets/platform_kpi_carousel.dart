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
        iconBgColor: const Color(0xFFEDF2FE),
        iconPosition: AppKpiIconPosition.bottomRight,
      ),
      AppKpiCard(
        title: 'Active Organizations',
        value: '${summary.activeOrganizations}',
        valueColor: const Color(0xFF15803D),
        accentColor: const Color(0xFF16A34A),
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF16A34A),
        iconBgColor: const Color(0xFFDCFCE7),
        iconPosition: AppKpiIconPosition.bottomRight,
      ),
      AppKpiCard(
        title: 'Suspended Organizations',
        value: '${summary.suspendedOrganizations}',
        accentColor: const Color(0xFFDC2626),
        valueColor: const Color(0xFFDC2626),
        icon: Icons.pause_circle_outline_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEE2E2),
        iconPosition: AppKpiIconPosition.bottomRight,
      ),
      AppKpiCard(
        title: 'Platform Administrators',
        value: '${summary.platformAdminsCount}',
        accentColor: const Color(0xFF475569),
        icon: Icons.admin_panel_settings_outlined,
        iconColor: const Color(0xFF475569),
        iconBgColor: const Color(0xFFF1F5F9),
        iconPosition: AppKpiIconPosition.bottomRight,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveKpiSection(cards: _buildCards(), cardHeight: 96);
  }
}
