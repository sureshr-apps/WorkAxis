import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/active_geofence_card.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/hero_attendance_card.dart';
import 'package:workaxis/features/employee_home/presentation/services/self_attendance_action_coordinator.dart';

/// Shows the existing employee self-punch controls to Branch Managers only
/// when their organization has enabled manager attendance.
class BranchManagerSelfAttendanceCard extends StatefulWidget {
  const BranchManagerSelfAttendanceCard({
    super.key,
    required this.access,
    required this.branchId,
  });

  final UserAccessContext access;
  final String branchId;

  @override
  State<BranchManagerSelfAttendanceCard> createState() =>
      _BranchManagerSelfAttendanceCardState();
}

class _BranchManagerSelfAttendanceCardState
    extends State<BranchManagerSelfAttendanceCard> {
  bool _checkingPolicy = true;
  bool _enabled = false;
  bool _isPreparingAction = false;
  String? _policyError;

  UserAccessContext? get _scopedAccess {
    final branch = widget.access.assignedBranches
        .where(
          (candidate) => candidate.id == widget.branchId && candidate.isActive,
        )
        .firstOrNull;
    if (branch == null) return null;
    return widget.access.copyWith(
      activeBranch: ActiveBranchContext.fromBranch(branch),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant BranchManagerSelfAttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId ||
        oldWidget.access.user.id != widget.access.user.id) {
      _load();
    }
  }

  Future<void> _load({bool requestLocationPermission = false}) async {
    final controller = Provider.of<EmployeeHomeController?>(
      context,
      listen: false,
    );
    if (controller == null) {
      setState(() {
        _checkingPolicy = false;
        _enabled = false;
      });
      return;
    }
    final access = _scopedAccess;
    if (access == null) {
      setState(() {
        _checkingPolicy = false;
        _enabled = false;
        _policyError =
            'Select an active branch you manage to record attendance.';
      });
      return;
    }
    setState(() {
      _checkingPolicy = true;
      _enabled = false;
      _policyError = null;
    });
    final policy = await controller.checkAttendancePolicy(userAccess: access);
    if (!mounted) return;
    if (policy == null) {
      setState(() {
        _checkingPolicy = false;
        _policyError =
            controller.actionErrorMessage ??
            'Attendance settings could not be checked. Try again.';
      });
      return;
    }
    if (!policy.requireBranchManagerAttendance) {
      setState(() {
        _checkingPolicy = false;
        _enabled = false;
      });
      return;
    }
    setState(() {
      _enabled = true;
      _checkingPolicy = false;
    });
    await controller.loadHomeSummary(
      access: access,
      requestLocationPermission: requestLocationPermission,
    );
  }

  Future<void> _handleAction(
    EmployeeHomeController controller, {
    bool checkOut = false,
  }) => SelfAttendanceActionCoordinator.perform(
    context: context,
    controller: controller,
    checkOut: checkOut,
    onPreparingChanged: (value) {
      if (mounted) setState(() => _isPreparingAction = value);
    },
  );

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EmployeeHomeController?>(context);
    if (controller == null) return const SizedBox.shrink();
    if (_checkingPolicy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_enabled && _policyError == null) return const SizedBox.shrink();
    if (_policyError != null) {
      return ErrorState(message: _policyError!, onRetry: _load);
    }
    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.hasError) {
      return ErrorState(
        message: controller.errorMessage ?? 'Attendance could not be loaded.',
        onRetry: _load,
      );
    }
    final summary = controller.summary;
    if (summary == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your attendance',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final hero = HeroAttendanceCard(
                summary: summary,
                isProcessing:
                    controller.isActionProcessing || _isPreparingAction,
                processingAction: controller.processingAction,
                onPrimaryAction: () => _handleAction(controller),
                onCheckOut: () => _handleAction(controller, checkOut: true),
              );
              final geofence = ActiveGeofenceCard(
                summary: summary,
                onRefreshLocation: summary.requireGeolocation
                    ? () => _load(requestLocationPermission: true)
                    : null,
              );
              if (constraints.maxWidth >= AppBreakpoints.employeeHomeWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: hero),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 5, child: geofence),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  hero,
                  const SizedBox(height: AppSpacing.lg),
                  geofence,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
