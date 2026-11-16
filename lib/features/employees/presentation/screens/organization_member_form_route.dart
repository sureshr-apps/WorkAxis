import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/employees/presentation/screens/organization_member_editor_screen.dart';

/// Routed entry for the employee add page ([memberId] null) and the edit page.
/// It re-resolves access (so branch assignments are current), loads the account
/// being edited within the active branch scope, then shows the editor.
class OrganizationMemberFormRoute extends StatefulWidget {
  const OrganizationMemberFormRoute({
    super.key,
    this.memberId,
    required this.listRoute,
    required this.listLabel,
  });

  final String? memberId;

  /// The directory this form belongs to, which scopes the back link.
  final String listRoute;
  final String listLabel;

  @override
  State<OrganizationMemberFormRoute> createState() =>
      _OrganizationMemberFormRouteState();
}

class _OrganizationMemberFormRouteState
    extends State<OrganizationMemberFormRoute> {
  UserAccessContext? _access;
  String? _branchId;
  OrganizationMember? _member;
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
  void didUpdateWidget(covariant OrganizationMemberFormRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberId != widget.memberId) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _notFound = false;
    });
    final accessController = context.read<AccessController>();
    await accessController.refreshAccess();
    if (!mounted) return;
    final access = accessController.accessContext;
    final branchId = context
        .read<BranchContextController>()
        .activeBranch
        ?.branchId;
    final controller = context.read<OrganizationMembersController>()
      ..clearActionError();
    final memberId = widget.memberId;
    final member = access == null || memberId == null
        ? null
        : await controller.getMember(
            access: access,
            memberId: memberId,
            activeBranchId: branchId,
          );
    if (!mounted) return;
    setState(() {
      _access = access;
      _branchId = branchId;
      _member = member;
      _notFound = access == null || (memberId != null && member == null);
      _loading = false;
    });
  }

  void _leave() => context.go(widget.listRoute);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final access = _access;
    if (_notFound || access == null) {
      return RecordNotFoundPage(
        backLabel: widget.listLabel,
        currentLabel: 'Employee',
        onBack: _leave,
        message: 'This account could not be found.',
        onRetry: _load,
      );
    }
    final controller = context.watch<OrganizationMembersController>();
    final branchId = _branchId;
    return OrganizationMemberEditorScreen(
      access: access,
      activeBranchId: branchId,
      member: _member,
      isSaving: controller.isSaving,
      saveErrorMessage: () => controller.actionErrorMessage,
      onSave: (draft, password) => controller.saveMember(
        access: access,
        member: draft,
        initialPassword: password,
        activeBranchId: branchId,
      ),
      backLabel: widget.listLabel,
      onClose: _leave,
      onSaved: _leave,
    );
  }
}
