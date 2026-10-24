import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/branch_dashboard/presentation/controllers/branch_dashboard_controller.dart';
import 'package:workaxis/features/branch_dashboard/presentation/screens/widgets/branch_header_banner.dart';
import 'package:workaxis/features/branch_dashboard/presentation/screens/widgets/branch_kpi_carousel.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/widgets/attendance_summary_card.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/widgets/attention_items_section.dart';

/// Home dashboard for Branch Manager role, scoped strictly to the active branch.
class BranchHomeScreen extends StatefulWidget {
  const BranchHomeScreen({super.key});

  @override
  State<BranchHomeScreen> createState() => _BranchHomeScreenState();
}

class _BranchHomeScreenState extends State<BranchHomeScreen> {
  String? _currentBranchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndLoad());
  }

  void _checkAndLoad() {
    final activeBranch = context.read<BranchContextController>().activeBranch;
    if (activeBranch != null) {
      _currentBranchId = activeBranch.branchId;
      context.read<BranchDashboardController>().loadDashboard(
        activeBranch.branchId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBranch = context.watch<BranchContextController>().activeBranch;
    final controller = context.watch<BranchDashboardController>();
    final isCompact = context.isCompact;

    // Reload if active branch changed in the background
    if (activeBranch != null && activeBranch.branchId != _currentBranchId) {
      _currentBranchId = activeBranch.branchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BranchDashboardController>().loadDashboard(
          activeBranch.branchId,
        );
      });
    }

    if (activeBranch == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 48,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No active branch selected.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.selectBranch),
                child: const Text('Select Branch'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () =>
            controller.loadDashboard(activeBranch.branchId, forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Active Branch Context Banner
              BranchHeaderBanner(activeBranch: activeBranch),
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
                  onRetry: () => controller.loadDashboard(
                    activeBranch.branchId,
                    forceRefresh: true,
                  ),
                ),
              ] else if (controller.summary != null) ...[
                // Branch-scoped KPI Carousel
                BranchKpiCarousel(summary: controller.summary!),
                const SizedBox(height: AppSpacing.xl),

                // Operational Content: Compact on phone, Two columns on tablet/web
                if (isCompact) ...[
                  AttendanceSummaryCard(
                    attendance: controller.summary!.attendance,
                    onViewDetails: () =>
                        context.go(AppRoutes.branchManagerAttendance),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AttentionItemsSection(
                    items: controller.summary!.attentionItems,
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Branch Attendance
                      Expanded(
                        flex: 5,
                        child: AttendanceSummaryCard(
                          attendance: controller.summary!.attendance,
                          onViewDetails: () =>
                              context.go(AppRoutes.branchManagerAttendance),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),

                      // Right Column: Branch Exceptions
                      Expanded(
                        flex: 6,
                        child: AttentionItemsSection(
                          items: controller.summary!.attentionItems,
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
