import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';
import 'package:workaxis/features/returns/presentation/screens/return_route_scope.dart';
import 'package:workaxis/features/returns/presentation/screens/submit_return_screen.dart';

/// Routed entry for recording a return. It re-resolves access (so the branch
/// choices are current), then shows [SubmitReturnScreen]. On success it
/// refreshes the returns list and goes back to [listRoute].
class SubmitReturnRoute extends StatefulWidget {
  const SubmitReturnRoute({
    super.key,
    required this.listRoute,
    required this.listLabel,
    this.returnId,
  });

  /// The list this form belongs to, which scopes the back link.
  final String listRoute;
  final String listLabel;
  final String? returnId;

  @override
  State<SubmitReturnRoute> createState() => _SubmitReturnRouteState();
}

class _SubmitReturnRouteState extends State<SubmitReturnRoute> {
  UserAccessContext? _access;
  ReturnItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final accessController = context.read<AccessController>();
    await accessController.refreshAccess();
    if (!mounted) return;
    final controller = context.read<ReturnsController>()..clearActionError();
    final access = accessController.accessContext;
    ReturnItem? item;
    if (widget.returnId != null && access != null) {
      await controller.loadReturns(
        access: access,
        activeBranchId: _branchScope(access),
      );
      if (!mounted) return;
      item = controller.items.where((r) => r.id == widget.returnId).firstOrNull;
    }
    setState(() {
      _access = access;
      _item = item;
      _loading = false;
    });
  }

  String? get _activeBranchId =>
      context.read<BranchContextController>().activeBranch?.branchId;

  String? _branchScope(UserAccessContext access) =>
      returnsBranchScope(access.user.role, _activeBranchId);

  /// Employees start on their first assigned branch; managers and admins start
  /// on the active branch.
  String? _initialBranchId(UserAccessContext access) {
    if (_item != null) return _item!.branchId;
    if (access.user.role == UserRole.employee) {
      return access.activeAssignedBranches.firstOrNull?.id;
    }
    return _activeBranchId;
  }

  Future<String?> _submit(
    UserAccessContext access,
    CreateReturnBatchInput batch,
  ) async {
    final controller = context.read<ReturnsController>();
    final scope = _branchScope(access);
    final saved = await controller.submitReturnBatch(
      access: access,
      branchId: batch.branchId ?? scope,
      input: batch,
    );
    if (!saved) {
      return controller.actionErrorMessage ??
          'The return request could not be submitted.';
    }
    if (mounted) _showSubmittedMessage(access.user.role, batch.items.length);
    return null;
  }

  Future<String?> _update(
    UserAccessContext access,
    ReturnItem item,
    CreateReturnInput input,
  ) async {
    final controller = context.read<ReturnsController>();
    final saved = await controller.updateReturn(
      access: access,
      activeBranchId: _branchScope(access),
      item: item,
      input: input,
    );
    if (!saved) {
      return controller.actionErrorMessage ??
          'The return request could not be updated.';
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return request updated.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
    }
    return null;
  }

  void _showSubmittedMessage(UserRole role, int count) {
    final isEmployee = role == UserRole.employee;
    final message = isEmployee
        ? (count == 1
              ? 'Return request submitted for manager review.'
              : '$count return items submitted for manager review.')
        : (count == 1
              ? 'Return recorded successfully.'
              : '$count return items recorded successfully.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.statusActive),
    );
  }

  void _leaveAfterSave(UserAccessContext access) {
    // The list may keep its state across this navigation, so it is refreshed
    // explicitly. Not awaited: leaving at once also stops a second submit.
    unawaited(
      context.read<ReturnsController>().loadReturns(
        access: access,
        activeBranchId: _branchScope(access),
      ),
    );
    _leave();
  }

  void _leave() => context.go(widget.listRoute);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final access = _access;
    if (access == null) {
      return RecordNotFoundPage(
        backLabel: widget.listLabel,
        currentLabel: widget.returnId == null ? 'New return' : 'Edit return',
        onBack: _leave,
        message: 'The return form could not be opened.',
        onRetry: _load,
      );
    }
    final item = _item;
    if (widget.returnId != null &&
        (item == null ||
            item.status != ReturnStatus.pending ||
            !item.wasSubmittedBy(access.user.id))) {
      return RecordNotFoundPage(
        backLabel: widget.listLabel,
        currentLabel: 'Edit return',
        onBack: _leave,
        message: 'Only the person who filed a pending return can edit it.',
        onRetry: _load,
      );
    }
    return SubmitReturnScreen(
      eyebrow: returnsEyebrow(access.user.role),
      backLabel: widget.listLabel,
      availableBranches: access.activeAssignedBranches,
      initialBranchId: _initialBranchId(access),
      initialReturn: item,
      onSubmitBatch: (batch) => _submit(access, batch),
      onUpdate: item == null ? null : (input) => _update(access, item, input),
      onClose: _leave,
      onSaved: () => _leaveAfterSave(access),
    );
  }
}
