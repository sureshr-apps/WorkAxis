import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/content_width_scope.dart';
import 'package:workaxis/core/responsive/responsive_sliver_page.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/domain/models/report_period.dart';
import 'package:workaxis/features/reports/presentation/controllers/reports_controller.dart';
import 'package:workaxis/features/reports/presentation/report_presentation.dart';
import 'package:workaxis/features/reports/presentation/screens/widgets/branch_performance_card.dart';
import 'package:workaxis/features/reports/presentation/screens/widgets/daily_trends_card.dart';
import 'package:workaxis/features/reports/presentation/screens/widgets/report_period_selector.dart';
import 'package:workaxis/features/reports/presentation/screens/widgets/return_categories_card.dart';

class OperationalReportsScreen extends StatefulWidget {
  const OperationalReportsScreen({super.key});

  @override
  State<OperationalReportsScreen> createState() =>
      _OperationalReportsScreenState();
}

class _OperationalReportsScreenState extends State<OperationalReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  String? get _activeBranchId =>
      context.read<BranchContextController>().activeBranch?.branchId;

  Future<void> _loadData() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    await context.read<ReportsController>().loadReports(
      access: access,
      activeBranchId: _activeBranchId,
    );
  }

  void _selectPeriod(ReportsController controller, ReportPeriod period) {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    controller.setPeriod(
      period,
      access: access,
      activeBranchId: _activeBranchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportsController>();
    final access = context.watch<AccessController>().accessContext;
    final branchName = context
        .watch<BranchContextController>()
        .activeBranch
        ?.branchName;
    final isManager = access?.user.role == UserRole.branchManager;
    final summary = controller.summary;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ResponsiveSliverPage(
          onRefresh: _loadData,
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                eyebrow: isManager
                    ? 'Branch Analytics'
                    : 'Operational Intelligence',
                title: isManager
                    ? 'Branch Operational Reports'
                    : 'Operational Reports',
                subtitle: isManager
                    ? 'Workforce attendance, punctuality trends, and returns for ${branchName ?? 'the active branch'}.'
                    : 'Organization-wide workforce compliance, shift hours, and inventory returns.',
                // Export is not implemented yet; never pretend it ran.
                action: AppButton.responsive(
                  text: 'Export (coming soon)',
                  iconData: Icons.download_outlined,
                  variant: AppButtonVariant.outlined,
                  onPressed: null,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: ReportPeriodSelector(
                selected: controller.selectedPeriod,
                onSelected: (period) => _selectPeriod(controller, period),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            if (controller.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (controller.errorMessage != null)
              SliverToBoxAdapter(
                child: ErrorState(
                  message: controller.errorMessage!,
                  onRetry: _loadData,
                ),
              )
            else if (summary != null) ...[
              SliverToBoxAdapter(child: _ReportKpis(summary: summary)),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              SliverToBoxAdapter(
                child: _ReportSections(
                  summary: summary,
                  isBranchManager: isManager,
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

class _ReportKpis extends StatelessWidget {
  const _ReportKpis({required this.summary});

  final OperationalReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasExceptions = (summary.exceptionCount ?? 0) > 0;
    return ResponsiveKpiSection(
      cards: [
        AppKpiCard(
          title: 'Attendance rate',
          value: ReportFormat.percent(summary.attendanceRate),
          accentColor: AppColors.statusActive,
          icon: Icons.verified_user_outlined,
          iconColor: AppColors.statusActiveText,
          iconBgColor: AppColors.statusActiveContainer,
        ),
        AppKpiCard(
          title: 'On-time arrival',
          value: ReportFormat.percent(summary.onTimeRate),
          icon: Icons.schedule_outlined,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryContainer,
        ),
        AppKpiCard(
          title: 'Total hours logged',
          value: ReportFormat.hours(summary.totalHoursLogged),
          icon: Icons.timer_outlined,
          iconColor: AppColors.secondary,
          iconBgColor: AppColors.kpiNeutralBackground,
        ),
        AppKpiCard(
          title: 'Exceptions flagged',
          value: ReportFormat.count(summary.exceptionCount),
          accentColor: hasExceptions ? AppColors.statusUrgent : null,
          icon: Icons.warning_amber_outlined,
          iconColor: hasExceptions
              ? AppColors.statusUrgentText
              : AppColors.secondary,
          iconBgColor: hasExceptions
              ? AppColors.statusUrgentContainer
              : AppColors.kpiNeutralBackground,
          valueColor: hasExceptions ? AppColors.statusUrgentText : null,
        ),
      ],
    );
  }
}

class _ReportSections extends StatelessWidget {
  const _ReportSections({required this.summary, required this.isBranchManager});

  final OperationalReportSummary summary;
  final bool isBranchManager;

  @override
  Widget build(BuildContext context) {
    final trends = DailyTrendsCard(trends: summary.dailyTrends);
    final categories = ReturnCategoriesCard(summary: summary);
    final branches = BranchPerformanceCard(
      branches: summary.branchMetrics,
      isBranchManager: isBranchManager,
    );

    if (ContentWidthScope.of(context) >= AppBreakpoints.wideContent) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: trends),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 5, child: categories),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          branches,
        ],
      );
    }
    return Column(
      children: [
        trends,
        const SizedBox(height: AppSpacing.lg),
        branches,
        const SizedBox(height: AppSpacing.lg),
        categories,
      ],
    );
  }
}
