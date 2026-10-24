import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/presentation/controllers/reports_controller.dart';

class OperationalReportsScreen extends StatefulWidget {
  const OperationalReportsScreen({super.key});

  @override
  State<OperationalReportsScreen> createState() => _OperationalReportsScreenState();
}

class _OperationalReportsScreenState extends State<OperationalReportsScreen> {
  static const _periods = ['This Week', 'This Month', 'Last Month', 'Quarter to Date'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    final activeBranchId = context.read<BranchContextController>().activeBranch?.branchId;
    await context.read<ReportsController>().loadReports(
      access: access,
      activeBranchId: activeBranchId,
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Operational report export generated (PDF & CSV).'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportsController>();
    final access = context.watch<AccessController>().accessContext;
    final branchContext = context.watch<BranchContextController>().activeBranch;
    final role = access?.user.role;
    final isManager = role == UserRole.branchManager;
    final branchName = isManager ? branchContext?.branchName : null;
    final summary = controller.summary;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsivePageContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Header with Export action
                  if (context.isCompact) ...[
                    AppPageHeader(
                      eyebrow: isManager ? 'Branch Analytics' : 'Operational Intelligence',
                      title: isManager ? 'Branch Operational Reports' : 'Operational Reports',
                      subtitle: isManager
                          ? 'Workforce attendance, punctuality trends, and returns for $branchName.'
                          : 'Organization-wide workforce compliance, shift hours, and inventory returns.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton(
                        text: 'Export Report',
                        iconData: Icons.download_outlined,
                        variant: AppButtonVariant.outlined,
                        onPressed: _exportReport,
                      ),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppPageHeader(
                            eyebrow: isManager ? 'Branch Analytics' : 'Operational Intelligence',
                            title: isManager ? 'Branch Operational Reports' : 'Operational Reports',
                            subtitle: isManager
                                ? 'Workforce attendance, punctuality trends, and returns for $branchName.'
                                : 'Organization-wide workforce compliance, shift hours, and inventory returns.',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        AppButton(
                          text: 'Export Report',
                          iconData: Icons.download_outlined,
                          variant: AppButtonVariant.outlined,
                          onPressed: _exportReport,
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.md),

                  // Period Selector Chips
                  _buildPeriodSelector(controller),
                  const SizedBox(height: AppSpacing.md),

                  if (controller.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (controller.errorMessage != null)
                    _buildErrorMessage(controller.errorMessage!)
                  else if (summary != null) ...[
                    // KPI Cards
                    ResponsiveKpiSection(
                      cardHeight: 96,
                      cards: [
                        AppKpiCard(
                          title: 'Attendance rate',
                          value: '${summary.attendanceRate}%',
                          accentColor: AppColors.statusActive,
                          icon: Icons.verified_user_outlined,
                          iconColor: AppColors.statusActiveText,
                          iconBgColor: AppColors.statusActiveContainer,
                        ),
                        AppKpiCard(
                          title: 'On-time arrival',
                          value: '${summary.onTimeRate}%',
                          icon: Icons.schedule_outlined,
                          iconColor: AppColors.primary,
                          iconBgColor: AppColors.primaryContainer,
                        ),
                        AppKpiCard(
                          title: 'Total hours logged',
                          value: '${summary.totalHoursLogged.toInt()}h',
                          icon: Icons.timer_outlined,
                          iconColor: AppColors.secondary,
                          iconBgColor: const Color(0xFFF1F5F9),
                        ),
                        AppKpiCard(
                          title: 'Exceptions flagged',
                          value: '${summary.exceptionCount}',
                          accentColor: summary.exceptionCount > 0 ? AppColors.statusUrgent : null,
                          icon: Icons.warning_amber_outlined,
                          iconColor: summary.exceptionCount > 0
                              ? AppColors.statusUrgentText
                              : AppColors.secondary,
                          iconBgColor: summary.exceptionCount > 0
                              ? AppColors.statusUrgentContainer
                              : const Color(0xFFF1F5F9),
                          valueColor: summary.exceptionCount > 0 ? AppColors.statusUrgentText : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Trends & Performance Section
                    _buildTrendsAndBreakdowns(context, summary, isManager),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ReportsController controller) {
    final access = context.read<AccessController>().accessContext;
    final activeBranchId = context.read<BranchContextController>().activeBranch?.branchId;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((p) {
          final isSelected = controller.selectedPeriod == p;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(
                p,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                if (access != null) {
                  controller.setPeriod(
                    p,
                    access: access,
                    activeBranchId: activeBranchId,
                  );
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerLowest,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.outlineSubtle,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendsAndBreakdowns(
    BuildContext context,
    OperationalReportSummary summary,
    bool isBranchManager,
  ) {
    final isDesktop = !context.isCompact && !context.isMedium;

    final weeklyTrendCard = _buildWeeklyTrendsCard(summary);
    final returnCategoriesCard = _buildReturnCategoriesCard(summary);
    final branchPerformanceCard = _buildBranchPerformanceCard(context, summary, isBranchManager);

    if (isDesktop) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: weeklyTrendCard),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 5, child: returnCategoriesCard),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          branchPerformanceCard,
        ],
      );
    }

    return Column(
      children: [
        weeklyTrendCard,
        const SizedBox(height: AppSpacing.lg),
        branchPerformanceCard,
        const SizedBox(height: AppSpacing.lg),
        returnCategoriesCard,
      ],
    );
  }

  Widget _buildWeeklyTrendsCard(OperationalReportSummary summary) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Daily Attendance Compliance',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'On-time punch compliance vs late and missing arrivals',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Column(
              children: summary.dailyTrends.map((trend) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: Text(
                          trend.dayName,
                          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 12,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: trend.onTimePercent.toInt(),
                                  child: Container(color: AppColors.statusActive),
                                ),
                                if (trend.latePercent > 0)
                                  Expanded(
                                    flex: trend.latePercent.toInt(),
                                    child: Container(color: AppColors.statusPending),
                                  ),
                                if (trend.absentPercent > 0)
                                  Expanded(
                                    flex: trend.absentPercent.toInt(),
                                    child: Container(color: AppColors.statusUrgent),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${trend.onTimePercent.toInt()}%',
                          textAlign: TextAlign.right,
                          style: AppTypography.labelMono.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                _buildLegendItem(AppColors.statusActive, 'On Time'),
                _buildLegendItem(AppColors.statusPending, 'Late'),
                _buildLegendItem(AppColors.statusUrgent, 'Missing / Absent'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildReturnCategoriesCard(OperationalReportSummary summary) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Return Reasons & Shrinkage',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Distribution of return causes (${summary.returnVolume} total items)',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Column(
              children: summary.returnCategories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cat.categoryName,
                              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('${cat.count} items (${cat.percentage}%)', style: AppTypography.labelMono.copyWith(fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cat.percentage / 100,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchPerformanceCard(BuildContext context, OperationalReportSummary summary, bool isBranchManager) {
    final isCompact = context.isCompact;

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isBranchManager ? 'Branch Operational Breakdown' : 'Branch Workforce Compliance',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isBranchManager
                  ? 'Attendance metrics and exceptions for this location'
                  : 'Operational status and attendance rates across assigned branches',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final b in summary.branchMetrics) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.branchName,
                                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              StatusChip(
                                label: b.attendanceRate >= 95 ? 'Optimal' : 'Review',
                                type: b.attendanceRate >= 95 ? StatusType.active : StatusType.pending,
                                width: 80,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${b.activeEmployees} active workforce members',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.xs,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Attendance: ', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                                  Text('${b.attendanceRate}%', style: AppTypography.labelMono.copyWith(fontWeight: FontWeight.w700, color: AppColors.statusActiveText)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Exceptions: ', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                                  Text(
                                    '${b.pendingExceptions} pending',
                                    style: AppTypography.labelMono.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: b.pendingExceptions > 0 ? AppColors.statusUrgentText : AppColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.branchName, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text('${b.activeEmployees} active workforce members', style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Attendance', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                                Text('${b.attendanceRate}%', style: AppTypography.labelMono.copyWith(fontWeight: FontWeight.w700, color: AppColors.statusActiveText)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Exceptions', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                                Text('${b.pendingExceptions} pending', style: AppTypography.labelMono.copyWith(fontWeight: FontWeight.w700, color: b.pendingExceptions > 0 ? AppColors.statusUrgentText : AppColors.onSurface)),
                              ],
                            ),
                          ),
                          StatusChip(
                            label: b.attendanceRate >= 95 ? 'Optimal' : 'Review',
                            type: b.attendanceRate >= 95 ? StatusType.active : StatusType.pending,
                            width: 90,
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String msg) {
    return Card(
      elevation: 0,
      color: AppColors.statusUrgentContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.statusUrgentText, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text(msg, style: const TextStyle(color: AppColors.statusUrgentText)),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
