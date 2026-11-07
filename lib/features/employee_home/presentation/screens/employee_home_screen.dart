import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/active_geofence_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/attendance_summary_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/employee_returns_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/hero_attendance_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/home_header_badges.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/shift_simulator_bar.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/today_assignment_card.dart';

/// Employee Home screen implementing the approved Stitch design.
class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always load on entry: a previous user's data must never be shown.
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    await context.read<EmployeeHomeController>().loadHomeSummary(
      access: access,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmployeeHomeController>();
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (summary != null) ...[
                    _header(controller, summary),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (controller.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl * 2,
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (controller.hasError)
                    ErrorState(
                      message:
                          controller.errorMessage ??
                          'An error occurred loading the dashboard.',
                      onRetry: _load,
                    )
                  else if (summary != null)
                    _body(controller, summary),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(
    EmployeeHomeController controller,
    EmployeeHomeSummary summary,
  ) {
    // Demo controls exist only for the mock backend in debug builds.
    final simulationBar = controller.simulator == null
        ? null
        : ShiftSimulatorBar(
            currentStatus: summary.currentStatus,
            onStatusChanged: controller.setSimulatedStatus,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Home',
          subtitle:
              '${summary.employeeName} • ${summary.organizationName} • ${summary.branchName}',
        ),
        const SizedBox(height: AppSpacing.sm),
        HomeHeaderBadges(summary: summary),
        if (simulationBar != null) ...[
          const SizedBox(height: AppSpacing.md),
          simulationBar,
        ],
      ],
    );
  }

  Widget _body(EmployeeHomeController controller, EmployeeHomeSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroAttendanceCard(
              summary: summary,
              isProcessing: controller.isActionProcessing,
              onPrimaryAction: () => _handlePrimaryAction(controller),
            ),
            const SizedBox(height: AppSpacing.lg),
            ActiveGeofenceCard(summary: summary),
          ],
        );
        final rightColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (TodayAssignmentCard.hasContent(summary)) ...[
              TodayAssignmentCard(summary: summary),
              const SizedBox(height: AppSpacing.lg),
            ],
            AttendanceSummaryCard(
              summary: summary,
              onViewHistory: () => context.go(AppRoutes.employeeAttendance),
            ),
            const SizedBox(height: AppSpacing.lg),
            EmployeeReturnsCard(
              summary: summary,
              onSubmitReturn: () => context.go(AppRoutes.employeeReturns),
              onViewReturns: () => context.go(AppRoutes.employeeReturns),
            ),
          ],
        );

        if (constraints.maxWidth >= AppBreakpoints.employeeHomeWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: leftColumn),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 5, child: rightColumn),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            leftColumn,
            const SizedBox(height: AppSpacing.lg),
            rightColumn,
          ],
        );
      },
    );
  }

  Future<void> _handlePrimaryAction(EmployeeHomeController controller) async {
    final recorded = await controller.performNextAttendanceAction();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          recorded
              ? 'Attendance updated: ${controller.summary?.currentStatus.displayName}'
              : (controller.actionErrorMessage ??
                    'Attendance could not be recorded.'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
