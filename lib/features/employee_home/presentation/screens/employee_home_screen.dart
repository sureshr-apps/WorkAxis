import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/active_geofence_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/attendance_summary_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/employee_returns_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/hero_attendance_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/home_header_badges.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/shift_simulator_bar.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/today_assignment_card.dart';
import 'package:workaxis/features/employee_home/presentation/services/self_attendance_action_coordinator.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Employee Home screen implementing the approved Stitch design.
class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  bool _isPreparingAttendanceAction = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always load on entry: a previous user's data must never be shown.
      if (mounted) _load();
    });
  }

  /// [requestLocationPermission] is true only for the explicit location
  /// refresh button; entry and pull-to-refresh never show the OS prompt.
  Future<void> _load({bool requestLocationPermission = false}) async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    final activeBranch = context.read<BranchContextController>().activeBranch;
    await context.read<EmployeeHomeController>().loadHomeSummary(
      access: activeBranch == null
          ? access
          : access.copyWith(activeBranch: activeBranch),
      requestLocationPermission: requestLocationPermission,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmployeeHomeController>();
    final summary = controller.summary;
    final access = context.watch<AccessController>().accessContext;
    final branchContext = context.watch<BranchContextController>();
    final employeeBranches = access?.user.role == UserRole.employee
        ? access!.activeAssignedBranches
        : <BranchSummary>[];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(),
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
                  if (employeeBranches.length > 1) ...[
                    _employeeBranchSelector(
                      branches: employeeBranches,
                      selectedBranchId:
                          branchContext.activeBranch?.branchId ??
                          access?.activeBranch?.branchId,
                      summary: summary,
                      isBusy:
                          controller.isLoading ||
                          controller.isActionProcessing ||
                          _isPreparingAttendanceAction,
                    ),
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
                      onRetry: () => _load(),
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

  Widget _employeeBranchSelector({
    required List<BranchSummary> branches,
    required String? selectedBranchId,
    required EmployeeHomeSummary? summary,
    required bool isBusy,
  }) {
    final sessionOpen =
        summary?.currentStatus == AttendanceStatus.checkedIn ||
        summary?.currentStatus == AttendanceStatus.onBreak;
    final selectedBranchIsAssigned = branches.any(
      (branch) => branch.id == selectedBranchId,
    );

    return DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Work location', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            sessionOpen
                ? 'This session is tied to ${summary!.branchName}. Check out here before switching branches.'
                : 'Choose the branch for your next attendance session.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (sessionOpen)
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Current session branch',
                border: OutlineInputBorder(),
              ),
              child: Text(summary!.branchName),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey(selectedBranchId),
              initialValue: selectedBranchIsAssigned ? selectedBranchId : null,
              decoration: const InputDecoration(
                labelText: 'Branch for your next check-in',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final branch in branches)
                  DropdownMenuItem(
                    value: branch.id,
                    child: Text(
                      branch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: isBusy ? null : _selectEmployeeBranch,
            ),
        ],
      ),
    );
  }

  void _selectEmployeeBranch(String? branchId) {
    if (branchId == null) return;
    final branches = context
        .read<AccessController>()
        .accessContext
        ?.activeAssignedBranches;
    if (branches == null) return;
    for (final branch in branches) {
      if (branch.id == branchId) {
        final selected = context.read<BranchContextController>().selectBranch(
          branch,
        );
        if (selected) _load();
        return;
      }
    }
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
              isProcessing:
                  controller.isActionProcessing || _isPreparingAttendanceAction,
              processingAction: controller.processingAction,
              onPrimaryAction: () => _handlePrimaryAction(controller),
              onCheckOut: () =>
                  _handlePrimaryAction(controller, checkOut: true),
            ),
            const SizedBox(height: AppSpacing.lg),
            ActiveGeofenceCard(
              summary: summary,
              onRefreshLocation: summary.requireGeolocation
                  ? () => _load(requestLocationPermission: true)
                  : null,
            ),
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

  Future<void> _handlePrimaryAction(
    EmployeeHomeController controller, {
    bool checkOut = false,
  }) => SelfAttendanceActionCoordinator.perform(
    context: context,
    controller: controller,
    checkOut: checkOut,
    onPreparingChanged: (value) {
      if (mounted) setState(() => _isPreparingAttendanceAction = value);
    },
  );
}
