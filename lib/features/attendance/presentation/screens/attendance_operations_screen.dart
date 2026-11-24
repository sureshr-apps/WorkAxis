import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_date_selector.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_exceptions_section.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_records_sliver.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

class AttendanceOperationsScreen extends StatefulWidget {
  const AttendanceOperationsScreen({super.key});

  @override
  State<AttendanceOperationsScreen> createState() =>
      _AttendanceOperationsScreenState();
}

class _AttendanceOperationsScreenState
    extends State<AttendanceOperationsScreen> {
  UserAccessContext? get _access =>
      context.read<AccessController>().accessContext;
  String? get _branchId =>
      context.read<BranchContextController>().activeBranch?.branchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({DateTime? date}) async {
    final access = _access;
    if (access == null) return;
    await context.read<AttendanceController>().loadAttendance(
      access: access,
      activeBranchId: access.user.role == UserRole.branchManager
          ? _branchId
          : null,
      date: date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AttendanceController>();
    final access = context.watch<AccessController>().accessContext;
    final branchContext = context.watch<BranchContextController>().activeBranch;
    final role = access?.user.role;
    final isEmployee = role == UserRole.employee;
    final isManager = role == UserRole.branchManager;
    final canReview =
        role == UserRole.orgAdmin || role == UserRole.branchManager;
    final summaries = AttendanceDaySummary.fromEntries(controller.entries);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pagePadding = context.responsivePagePadding.horizontal / 2;
              final side = math.max(
                pagePadding,
                (constraints.maxWidth - AppBreakpoints.maxPageWidth) / 2 +
                    pagePadding,
              );
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      context.responsivePagePadding.top,
                      side,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildTop(
                        controller,
                        access,
                        isEmployee: isEmployee,
                        isManager: isManager,
                        canReview: canReview,
                        branchName: branchContext?.branchName,
                        branchId: branchContext?.branchId,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: side),
                    sliver: _buildBody(
                      controller,
                      access,
                      summaries: summaries,
                      needsBranch: isManager && branchContext == null,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTop(
    AttendanceController controller,
    UserAccessContext? access, {
    required bool isEmployee,
    required bool isManager,
    required bool canReview,
    required String? branchName,
    required String? branchId,
  }) {
    final title = isEmployee
        ? 'My Attendance'
        : isManager
        ? 'Branch Attendance'
        : 'Organization Attendance';
    final late = controller.lateCount;
    final exceptions = controller.needsReviewCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPageHeader(
          eyebrow: isEmployee ? 'Self Service' : 'Time & Attendance',
          title: title,
          subtitle: isEmployee
              ? 'Review your check-in history and shift records.'
              : isManager
              ? 'Verify attendance and resolve exceptions for ${branchName ?? 'your branch'}.'
              : 'Verify check-ins and resolve organization attendance exceptions.',
          actions: canReview && access != null
              ? [
                  AppButton.primary(
                    text: 'Group Check-In',
                    iconData: Icons.group_add_outlined,
                    isFullWidth: false,
                    onPressed: () {
                      context.push(_groupCheckInPath(access.user.role));
                    },
                  ),
                ]
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AttendanceDateSelector(
          selectedDate: controller.selectedDate,
          today: controller.today,
          yesterday: controller.yesterday,
          onSelected: (date) => _load(date: date),
        ),
        const SizedBox(height: AppSpacing.md),
        ResponsiveKpiSection(
          cardHeight: 96,
          cards: [
            AppKpiCard(
              title: 'On time',
              value: '${controller.onTimeCount}',
              accentColor: AppColors.statusActive,
              icon: Icons.check_circle_outline,
              iconColor: AppColors.statusActiveText,
              iconBgColor: AppColors.statusActiveContainer,
            ),
            AppKpiCard(
              title: 'Late arrivals',
              value: '$late',
              icon: Icons.schedule_outlined,
              accentColor: late == 0 ? null : AppColors.statusPending,
              iconColor: late == 0
                  ? AppColors.secondary
                  : AppColors.statusPendingText,
              iconBgColor: late == 0
                  ? AppColors.kpiNeutralBackground
                  : AppColors.statusPendingContainer,
              valueColor: late == 0 ? null : AppColors.statusPendingText,
            ),
            AppKpiCard(
              title: 'Needs review',
              value: '$exceptions',
              icon: Icons.rule_outlined,
              accentColor: exceptions == 0 ? null : AppColors.statusUrgent,
              iconColor: exceptions == 0
                  ? AppColors.secondary
                  : AppColors.statusUrgentText,
              iconBgColor: exceptions == 0
                  ? AppColors.kpiNeutralBackground
                  : AppColors.statusUrgentContainer,
              valueColor: exceptions == 0 ? null : AppColors.statusUrgentText,
            ),
          ],
        ),
        if (canReview && access != null && (!isManager || branchId != null))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: AttendanceExceptionsSection(
              access: access,
              activeBranchId: isManager ? branchId : null,
              onDecided: _load,
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                isEmployee ? 'My shift records' : 'Attendance records',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${controller.entries.length} records',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildBody(
    AttendanceController controller,
    UserAccessContext? access, {
    required List<AttendanceDaySummary> summaries,
    required bool needsBranch,
  }) {
    if (needsBranch) {
      return _message(
        const EmptyState(
          icon: Icons.store_outlined,
          title: 'Select an active branch',
          message: 'Choose one of your assigned branches before reviewing attendance.',
        ),
      );
    }
    if (controller.isLoading) {
      return _message(
        const Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (controller.errorMessage != null) {
      return _message(
        ErrorState(message: controller.errorMessage!, onRetry: _load),
      );
    }
    if (summaries.isEmpty) {
      return _message(
        const EmptyState(
          icon: Icons.event_available_outlined,
          title: 'No attendance records',
          message: 'No check-ins or shift records were found for this date.',
        ),
      );
    }
    return AttendanceRecordsSliver(
      summaries: summaries,
      branchNamesFor: (summary) =>
          summary.branchIds.map((id) => _branchName(id, access)).join(', '),
      onDetails: (summary) {
        final role = access?.user.role;
        if (role != null && summary.sessions.isNotEmpty) {
          context.push(_detailsPath(role, summary.sessions.first.id));
        }
      },
    );
  }

  Widget _message(Widget child) => SliverToBoxAdapter(child: child);

  /// Each role reaches attendance under its own route prefix.
  String _groupCheckInPath(UserRole role) => role == UserRole.branchManager
      ? AppRoutes.branchManagerAttendanceGroupPath
      : AppRoutes.orgAdminAttendanceGroupPath;

  String _detailsPath(UserRole role, String id) {
    if (role == UserRole.employee) {
      return AppRoutes.employeeAttendanceDetailsPath(id);
    }
    if (role == UserRole.branchManager) {
      return AppRoutes.branchManagerAttendanceDetailsPath(id);
    }
    return AppRoutes.orgAdminAttendanceDetailsPath(id);
  }

  String _branchName(String id, UserAccessContext? access) {
    for (final branch in access?.assignedBranches ?? const []) {
      if (branch.id == id) return branch.name;
    }
    return 'Unknown branch';
  }
}
