import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/presentation/controllers/branch_management_controller.dart';
import 'package:workaxis/features/branches/presentation/screens/branch_editor_screen.dart';

/// Routed entry for the branch add page ([branchId] null) and the edit page.
/// It resolves the access context, the branch being edited and the manager
/// options before showing [BranchEditorScreen].
class BranchEditorRoute extends StatefulWidget {
  const BranchEditorRoute({super.key, this.branchId});

  final String? branchId;

  @override
  State<BranchEditorRoute> createState() => _BranchEditorRouteState();
}

class _BranchEditorRouteState extends State<BranchEditorRoute> {
  UserAccessContext? _access;
  BranchRecord? _branch;
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant BranchEditorRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId) _load();
  }

  /// Re-resolves access before the form opens, so the editor sees the current
  /// branch assignments and manager list.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _notFound = false;
    });
    final accessController = context.read<AccessController>();
    await accessController.refreshAccess();
    if (!mounted) return;
    final access = accessController.accessContext;
    final controller = context.read<BranchManagementController>()
      ..clearActionError();
    BranchRecord? branch;
    if (access != null && access.organization != null) {
      await controller.loadManagerOptions(access);
      final branchId = widget.branchId;
      if (branchId != null) {
        branch = await controller.getBranch(access, branchId);
      }
    }
    if (!mounted) return;
    setState(() {
      _access = access;
      _branch = branch;
      _notFound =
          access?.organization == null ||
          (widget.branchId != null && branch == null);
      _loading = false;
    });
  }

  void _leave() => context.go(AppRoutes.orgAdminBranches);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final access = _access;
    if (_notFound || access == null) {
      return RecordNotFoundPage(
        backLabel: 'Branch Management',
        currentLabel: 'Branch',
        onBack: _leave,
        message: 'This branch could not be found.',
        onRetry: _load,
      );
    }
    final controller = context.watch<BranchManagementController>();
    return BranchEditorScreen(
      branch: _branch,
      organizationId: access.organization!.id,
      managerOptions: controller.managerOptions,
      isSaving: controller.isSaving,
      readActionError: () => controller.actionErrorMessage,
      onSave: (record) => controller.saveBranch(access: access, branch: record),
      backLabel: 'Branch Management',
      onClose: _leave,
      onSaved: () async {
        await context.read<AccessController>().refreshAccess();
        if (mounted) _leave();
      },
    );
  }
}
