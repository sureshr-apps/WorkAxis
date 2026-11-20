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
import 'package:workaxis/features/returns/presentation/screens/return_details_screen.dart';
import 'package:workaxis/features/returns/presentation/screens/return_route_scope.dart';

/// Routed entry for one return request. It re-resolves access, finds the
/// return in the loaded list (loading the list when it is absent), then shows
/// [ReturnDetailsScreen]. A successful review refreshes the list and goes back
/// to [listRoute].
class ReturnDetailsRoute extends StatefulWidget {
  const ReturnDetailsRoute({
    super.key,
    required this.returnId,
    required this.listRoute,
    required this.listLabel,
  });

  final String returnId;

  /// The list this page belongs to, which scopes the back link.
  final String listRoute;
  final String listLabel;

  @override
  State<ReturnDetailsRoute> createState() => _ReturnDetailsRouteState();
}

class _ReturnDetailsRouteState extends State<ReturnDetailsRoute> {
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
    final access = accessController.accessContext;
    final controller = context.read<ReturnsController>()..clearActionError();
    var item = _findItem(controller);
    if (access != null && item == null) {
      // Not in the loaded list (a deep link or a fresh session): load it and
      // look again.
      await controller.loadReturns(
        access: access,
        activeBranchId: _branchScope(access),
      );
      if (!mounted) return;
      item = _findItem(controller);
    }
    setState(() {
      _access = access;
      _item = item;
      _loading = false;
    });
  }

  ReturnItem? _findItem(ReturnsController controller) =>
      controller.items.where((i) => i.id == widget.returnId).firstOrNull;

  String? get _activeBranchId =>
      context.read<BranchContextController>().activeBranch?.branchId;

  String? _branchScope(UserAccessContext access) =>
      returnsBranchScope(access.user.role, _activeBranchId);

  Future<String?> _review(
    UserAccessContext access,
    ReturnItem item,
    ReturnStatus decision,
    String notes,
  ) async {
    final controller = context.read<ReturnsController>();
    final saved = await controller.reviewReturn(
      access: access,
      activeBranchId: _branchScope(access),
      item: item,
      decision: decision,
      reviewerNotes: notes,
    );
    if (!saved) {
      return controller.actionErrorMessage ??
          'The decision could not be saved.';
    }
    if (mounted) _showDecisionMessage(item, decision);
    return null;
  }

  void _showDecisionMessage(ReturnItem item, ReturnStatus decision) {
    final approved = decision == ReturnStatus.approved;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? 'Return request #${item.id} approved.'
              : 'Return request #${item.id} rejected.',
        ),
        backgroundColor: approved
            ? AppColors.statusActive
            : AppColors.statusUrgent,
      ),
    );
  }

  void _leaveAfterReview(UserAccessContext access) {
    // The list may keep its state across this navigation, so it is refreshed
    // explicitly. Not awaited: the page is left at once.
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
    final item = _item;
    if (access == null || item == null) {
      return RecordNotFoundPage(
        backLabel: widget.listLabel,
        currentLabel: 'Return',
        onBack: _leave,
        message: 'This return request could not be found.',
        onRetry: _load,
      );
    }
    final role = access.user.role;
    final isOwnBranchManagerReturn =
        role == UserRole.branchManager && item.wasSubmittedBy(access.user.id);
    final canReview = canReviewReturn(role, access.user.id, item);
    return ReturnDetailsScreen(
      item: item,
      eyebrow: returnsEyebrow(role),
      subtitle: isOwnBranchManagerReturn && item.status == ReturnStatus.pending
          ? 'You submitted this return. Another Branch Manager or an Organization Admin must review it.'
          : null,
      backLabel: widget.listLabel,
      onClose: _leave,
      canReview: canReview,
      onReviewDecision: canReview
          ? (decision, notes) => _review(access, item, decision, notes)
          : null,
      onReviewed: () => _leaveAfterReview(access),
    );
  }
}
