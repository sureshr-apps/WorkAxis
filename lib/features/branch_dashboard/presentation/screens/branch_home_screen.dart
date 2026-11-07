import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/branch_dashboard/presentation/controllers/branch_dashboard_controller.dart';
import 'package:workaxis/features/branch_dashboard/presentation/screens/widgets/branch_header_banner.dart';
import 'package:workaxis/features/branch_dashboard/presentation/screens/widgets/branch_kpi_carousel.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/widgets/attention_items_section.dart';
import 'package:workaxis/shared/widgets/attendance_summary_card.dart';

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
      _load(activeBranch.branchId);
    }
  }

  void _load(String branchId, {bool forceRefresh = false}) {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    context.read<BranchDashboardController>().loadDashboard(
      access: access,
      branchId: branchId,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBranch = context.watch<BranchContextController>().activeBranch;
    final controller = context.watch<BranchDashboardController>();

    // Reload if active branch changed in the background.
    if (activeBranch != null && activeBranch.branchId != _currentBranchId) {
      _currentBranchId = activeBranch.branchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(activeBranch.branchId);
      });
    }

    if (activeBranch == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: EmptyState(
            icon: Icons.storefront_outlined,
            title: 'No active branch selected.',
            action: AppButton.primary(
              text: 'Select Branch',
              isFullWidth: false,
              onPressed: () => context.go(AppRoutes.selectBranch),
            ),
          ),
        ),
      );
    }

    final summary = controller.summary;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              _load(activeBranch.branchId, forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsivePageContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BranchHeaderBanner(activeBranch: activeBranch),
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
                      onRetry: () =>
                          _load(activeBranch.branchId, forceRefresh: true),
                    )
                  else if (summary != null)
                    _BranchDashboardBody(summary: summary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchDashboardBody extends StatelessWidget {
  const _BranchDashboardBody({required this.summary});

  final BranchDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final attendanceCard = AttendanceSummaryCard(
      attendance: summary.attendance,
      onViewDetails: () => context.go(AppRoutes.branchManagerAttendance),
    );
    final attentionSection = AttentionItemsSection(
      items: summary.attentionItems,
      branchScope: true,
      onViewAll: () => context.go(AppRoutes.branchManagerAttendance),
      onItemAction: (_, route) => context.go(route),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BranchKpiCarousel(summary: summary),
        const SizedBox(height: AppSpacing.xl),
        if (context.isCompact) ...[
          attendanceCard,
          const SizedBox(height: AppSpacing.lg),
          attentionSection,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: attendanceCard),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 6, child: attentionSection),
            ],
          ),
      ],
    );
  }
}
