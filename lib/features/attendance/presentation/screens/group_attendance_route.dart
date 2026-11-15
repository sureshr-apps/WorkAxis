import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/group_attendance_screen.dart';

/// Routed entry for the group check-in page. It reads the current access, the
/// active branch and the attendance list, then shows [GroupAttendanceScreen].
/// A recorded batch is confirmed on the list the page came from.
class GroupAttendanceRoute extends StatefulWidget {
  const GroupAttendanceRoute({
    super.key,
    required this.listRoute,
    required this.listLabel,
  });

  /// The attendance list this page belongs to; back and success go there.
  final String listRoute;
  final String listLabel;

  @override
  State<GroupAttendanceRoute> createState() => _GroupAttendanceRouteState();
}

class _GroupAttendanceRouteState extends State<GroupAttendanceRoute> {
  @override
  void initState() {
    super.initState();
    // A failure left over from an earlier action must not show on this page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AttendanceController>().clearActionError();
    });
  }

  void _leave() => context.go(widget.listRoute);

  void _onSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Group attendance check-in recorded successfully.'),
        backgroundColor: AppColors.statusActiveText,
      ),
    );
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessController>().accessContext;
    if (access == null) {
      return RecordNotFoundPage(
        backLabel: widget.listLabel,
        currentLabel: 'Group Check-In',
        onBack: _leave,
        message: 'Group check-in is unavailable. Sign in again to continue.',
        onRetry: () => context.read<AccessController>().refreshAccess(),
      );
    }
    final controller = context.watch<AttendanceController>();
    return GroupAttendanceScreen(
      access: access,
      initialBranchId: context
          .read<BranchContextController>()
          .activeBranch
          ?.branchId,
      initialDate: controller.selectedDate,
      existingEntries: controller.entries,
      onSubmit: (request) =>
          controller.markGroupAttendance(access: access, request: request),
      failureMessage: () => controller.actionErrorMessage,
      backLabel: widget.listLabel,
      onClose: _leave,
      onSaved: _onSaved,
    );
  }
}
