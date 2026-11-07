import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';
import 'package:workaxis/features/organization_dashboard/presentation/controllers/organization_dashboard_controller.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/widgets/attention_items_section.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/widgets/org_kpi_carousel.dart';
import 'package:workaxis/shared/widgets/attendance_summary_card.dart';

/// Home dashboard for Organization Admin role.
class OrganizationHomeScreen extends StatefulWidget {
  const OrganizationHomeScreen({super.key});

  @override
  State<OrganizationHomeScreen> createState() => _OrganizationHomeScreenState();
}

class _OrganizationHomeScreenState extends State<OrganizationHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always load on entry: a previous user's data must never be shown.
      _load();
    });
  }

  Future<void> _load() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    await context.read<OrganizationDashboardController>().loadDashboard(
      access: access,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrganizationDashboardController>();
    final summary = controller.summary;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsivePageContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppPageHeader(title: 'Organization Overview'),
                  const SizedBox(height: AppSpacing.lg),
                  if (controller.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (controller.hasError)
                    ErrorBanner(
                      message:
                          controller.errorMessage ??
                          'An error occurred loading the dashboard.',
                      onRetry: _load,
                    )
                  else if (summary != null)
                    _DashboardBody(summary: summary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.summary});

  final OrganizationDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final attendanceCard = AttendanceSummaryCard(
      attendance: summary.attendance,
      branchSnapshots: summary.branchSnapshots,
      onViewDetails: () => context.go(AppRoutes.orgAdminAttendance),
    );
    final attentionSection = AttentionItemsSection(
      items: summary.attentionItems,
      branchScope: false,
      onViewAll: () => context.go(AppRoutes.orgAdminAttendance),
      onItemAction: (_, route) => context.go(route),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrgKpiCarousel(summary: summary),
        const SizedBox(height: AppSpacing.xl),
        if (context.isCompact) ...[
          attendanceCard,
          const SizedBox(height: AppSpacing.lg),
          attentionSection,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: attendanceCard),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 5, child: attentionSection),
            ],
          ),
      ],
    );
  }
}
