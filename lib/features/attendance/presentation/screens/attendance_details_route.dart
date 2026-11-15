import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/attendance_details_screen.dart';

/// Routed entry for one attendance record. The record is looked up in the
/// attendance list already loaded; when it is missing, the list is loaded for
/// the active branch and searched again before the not-found page is shown.
class AttendanceDetailsRoute extends StatefulWidget {
  const AttendanceDetailsRoute({
    super.key,
    required this.entryId,
    required this.listRoute,
    required this.listLabel,
  });

  final String entryId;

  /// The attendance list this record belongs to; back goes there.
  final String listRoute;
  final String listLabel;

  @override
  State<AttendanceDetailsRoute> createState() => _AttendanceDetailsRouteState();
}

class _AttendanceDetailsRouteState extends State<AttendanceDetailsRoute> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant AttendanceDetailsRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entryId != widget.entryId) _load();
  }

  Future<void> _load() async {
    final access = context.read<AccessController>().accessContext;
    final controller = context.read<AttendanceController>();
    if (access != null && _find(controller.entries) == null) {
      setState(() => _loading = true);
      final branchId = context
          .read<BranchContextController>()
          .activeBranch
          ?.branchId;
      await controller.loadAttendance(access: access, activeBranchId: branchId);
    }
    if (mounted) setState(() => _loading = false);
  }

  AttendanceEntry? _find(List<AttendanceEntry> entries) =>
      entries.where((entry) => entry.id == widget.entryId).firstOrNull;

  /// Branch names come from the access context; an unknown branch is labelled
  /// rather than guessed.
  String _branchName(AttendanceEntry entry, UserAccessContext access) =>
      access.assignedBranches
          .where((branch) => branch.id == entry.branchId)
          .firstOrNull
          ?.name ??
      'Unknown branch';

  void _leave() => context.go(widget.listRoute);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final access = context.watch<AccessController>().accessContext;
    final entry = _find(context.watch<AttendanceController>().entries);
    if (access == null || entry == null) {
      return RecordNotFoundPage(
        backLabel: widget.listLabel,
        currentLabel: 'Attendance details',
        onBack: _leave,
        message: 'This attendance record could not be found.',
        onRetry: _load,
      );
    }
    return AttendanceDetailsScreen(
      entry: entry,
      branchName: _branchName(entry, access),
      backLabel: widget.listLabel,
      onClose: _leave,
    );
  }
}
