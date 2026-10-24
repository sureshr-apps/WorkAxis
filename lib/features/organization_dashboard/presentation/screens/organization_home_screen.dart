import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/organization_dashboard/presentation/controllers/organization_dashboard_controller.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/widgets/attendance_summary_card.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/widgets/attention_items_section.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/widgets/org_kpi_carousel.dart';

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
      final controller = context.read<OrganizationDashboardController>();
      if (controller.status == OrganizationDashboardStatus.initial) {
        controller.loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrganizationDashboardController>();
    final isCompact = context.isCompact;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => controller.loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Page Title (Stitch specification: Clean Display-LG Headline)
              const AppPageHeader(title: 'Organization Overview'),
              const SizedBox(height: AppSpacing.lg),

              if (controller.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.hasError) ...[
                ErrorBanner(
                  message:
                      controller.errorMessage ??
                      'An error occurred loading the dashboard.',
                  onRetry: () => controller.loadDashboard(),
                ),
              ] else if (controller.summary != null) ...[
                // Operational Metric Row (5 KPI Cards)
                OrgKpiCarousel(summary: controller.summary!),
                const SizedBox(height: AppSpacing.xl),

                // Primary Operations Two-Column Split (7-5 grid on desktop/tablet)
                if (isCompact) ...[
                  // Phone: Stacked vertically
                  AttendanceSummaryCard(
                    attendance: controller.summary!.attendance,
                    branchSnapshots: controller.summary!.branchSnapshots,
                    onViewDetails: () =>
                        context.go(AppRoutes.orgAdminAttendance),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const EveningShiftTransitionCard(),
                  const SizedBox(height: AppSpacing.lg),
                  AttentionItemsSection(
                    items: controller.summary!.attentionItems,
                    onViewAll: () => context.go(AppRoutes.orgAdminAttendance),
                  ),
                ] else ...[
                  // Tablet & Web: Two-column layout (7 cols left, 5 cols right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column 1: Today's Attendance + Evening Shift Transition
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            AttendanceSummaryCard(
                              attendance: controller.summary!.attendance,
                              branchSnapshots:
                                  controller.summary!.branchSnapshots,
                              onViewDetails: () =>
                                  context.go(AppRoutes.orgAdminAttendance),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const EveningShiftTransitionCard(),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),

                      // Column 2: Needs Attention
                      Expanded(
                        flex: 5,
                        child: AttentionItemsSection(
                          items: controller.summary!.attentionItems,
                          onViewAll: () =>
                              context.go(AppRoutes.orgAdminAttendance),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
}
