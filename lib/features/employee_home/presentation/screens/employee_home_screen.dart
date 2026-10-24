import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/active_geofence_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/attendance_summary_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/employee_returns_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/hero_attendance_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/safety_notices_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/shift_simulator_bar.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/today_assignment_card.dart';

/// Pixel-perfect Employee Home Screen implementing the approved Stitch design.
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
      final controller = context.read<EmployeeHomeController>();
      if (controller.status == EmployeeHomeStatus.initial) {
        controller.loadHomeSummary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmployeeHomeController>();
    final summary = controller.summary;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => controller.loadHomeSummary(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  // Top Sub-Header & Simulation Bar
                  if (summary != null) ...[
                    _buildSubHeader(context, controller, summary),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  if (controller.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (controller.hasError) ...[
                    ErrorBanner(
                      message: controller.errorMessage ??
                          'An error occurred loading the dashboard.',
                      onRetry: () => controller.loadHomeSummary(),
                    ),
                  ] else if (summary != null) ...[
                    // Responsive Grid Layout: 2-column on desktop (>=1024), stacked on tablet/mobile
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktopLayout = constraints.maxWidth >= 1024;

                        final leftColumn = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            HeroAttendanceCard(
                              summary: summary,
                              isProcessing: controller.isActionProcessing,
                              onPrimaryAction: () =>
                                  _handlePrimaryAction(context, controller),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ActiveGeofenceCard(summary: summary),
                          ],
                        );

                        final rightColumn = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TodayAssignmentCard(summary: summary),
                            const SizedBox(height: AppSpacing.lg),
                            AttendanceSummaryCard(
                              summary: summary,
                              onViewHistory: () =>
                                  context.go(AppRoutes.employeeAttendance),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            EmployeeReturnsCard(
                              summary: summary,
                              onSubmitReturn: () =>
                                  context.go(AppRoutes.employeeReturns),
                              onViewReturns: () =>
                                  context.go(AppRoutes.employeeReturns),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const SafetyNoticesCard(),
                          ],
                        );

                        if (isDesktopLayout) {
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
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildSubHeader(
    BuildContext context,
    EmployeeHomeController controller,
    dynamic summary,
  ) {
    final titleAndBadges = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        Text(
          'Home',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            summary.shiftCode,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D1C2E),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.statusActiveContainer,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.statusActiveBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock,
                size: 13,
                color: AppColors.statusActiveText,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  summary.locationStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusActiveText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final subtitle = Text(
      '${summary.employeeName} • ${summary.organizationName} • ${summary.branchName}',
      style: GoogleFonts.inter(
        fontSize: 13.5,
        color: AppColors.onSurfaceVariant,
      ),
    );

    final simulationBar = ShiftSimulatorBar(
      currentStatus: summary.currentStatus,
      onStatusChanged: (status) => controller.setSimulatedStatus(status),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleAndBadges,
              const SizedBox(height: 6),
              subtitle,
              const SizedBox(height: AppSpacing.md),
              simulationBar,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleAndBadges,
                  const SizedBox(height: 6),
                  subtitle,
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            simulationBar,
          ],
        );
      },
    );
  }

  void _handlePrimaryAction(
    BuildContext context,
    EmployeeHomeController controller,
  ) async {
    await controller.performNextAttendanceAction();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance updated: ${controller.summary?.currentStatus.displayName}',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
