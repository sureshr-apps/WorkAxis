import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/async_confirmation_dialog.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_policy.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_policy.dart';
import 'package:workaxis/features/leave_policy/presentation/controllers/leave_policy_controller.dart';
import 'package:workaxis/features/leave_policy/presentation/widgets/leave_type_editor_dialog.dart';
import 'package:workaxis/features/leave_policy/presentation/widgets/leave_type_tile.dart';
import 'package:workaxis/features/settings/presentation/widgets/settings_section_card.dart';

/// Organization Settings card for the leave policy (Organization Admins
/// only): monthly accrual, and the leave types with their yearly allowance.
///
/// Every change saves immediately, independent of the page's Save button.
class LeavePolicySection extends StatefulWidget {
  const LeavePolicySection({super.key});

  @override
  State<LeavePolicySection> createState() => _LeavePolicySectionState();
}

class _LeavePolicySectionState extends State<LeavePolicySection> {
  /// While a dialog is open it shows change failures itself, so the card's
  /// banner is hidden to avoid repeating them.
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  UserAccessContext? get _access {
    final access = context.read<AccessController>().accessContext;
    return access?.user.role == UserRole.orgAdmin ? access : null;
  }

  Future<void> _load() async {
    if (!mounted) return;
    final access = _access;
    if (access == null) return;
    await context.read<LeavePolicyController>().load(access);
  }

  Future<void> _setAccrual(bool enabled) async {
    final access = _access;
    if (access == null) return;
    await context.read<LeavePolicyController>().setMonthlyAccrual(
      access,
      enabled,
    );
  }

  Future<void> _openEditor([LeaveTypePolicy? type]) async {
    final access = _access;
    if (access == null) return;
    final controller = context.read<LeavePolicyController>();
    await _inDialog(
      controller,
      () => LeaveTypeEditorDialog.show(
        context,
        leaveType: type,
        onSave: (input) => controller.saveLeaveType(access, input),
        actionErrorMessage: () => controller.actionErrorMessage,
      ),
    );
  }

  Future<void> _confirmRemove(LeaveTypePolicy type) async {
    final access = _access;
    if (access == null) return;
    final controller = context.read<LeavePolicyController>();
    await _inDialog(
      controller,
      () => showAsyncConfirmationDialog(
        context: context,
        title: 'Remove leave type?',
        content: Text(
          '"${type.name}" will no longer be offered for new leave requests. '
          'Existing requests keep it.',
          style: AppTypography.bodyMedium,
        ),
        confirmLabel: 'Remove',
        destructive: true,
        onConfirm: () => controller.archiveLeaveType(access, type),
        failureMessage: () => controller.actionErrorMessage,
      ),
    );
  }

  Future<void> _inDialog(
    LeavePolicyController controller,
    Future<Object?> Function() show,
  ) async {
    controller.clearActionError();
    setState(() => _dialogOpen = true);
    await show();
    controller.clearActionError();
    if (mounted) setState(() => _dialogOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessController>().accessContext;
    if (access?.user.role != UserRole.orgAdmin) return const SizedBox.shrink();
    final controller = context.watch<LeavePolicyController>();
    final policy = controller.policy;

    return SettingsSectionCard(
      icon: Icons.event_available_outlined,
      title: 'Leave Policy',
      subtitle: 'Yearly allowances per leave type, carry-forward, and monthly accrual. Changes save immediately.',
      child: policy != null
          ? _PolicyBody(
              policy: policy,
              controller: controller,
              showActionError: !_dialogOpen,
              onAccrualChanged: _setAccrual,
              // Not awaited: the dialog shows progress, not the button.
              onAdd: () {
                _openEditor();
              },
              onEdit: _openEditor,
              onRemove: _confirmRemove,
            )
          : controller.status == LeavePolicyLoadStatus.error
          ? ErrorBanner(
              message:
                  controller.loadErrorMessage ??
                  'Could not load the leave policy.',
              onRetry: _load,
            )
          : const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

class _PolicyBody extends StatelessWidget {
  const _PolicyBody({
    required this.policy,
    required this.controller,
    required this.showActionError,
    required this.onAccrualChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final LeavePolicy policy;
  final LeavePolicyController controller;
  final bool showActionError;
  final ValueChanged<bool> onAccrualChanged;
  final VoidCallback onAdd;
  final ValueChanged<LeaveTypePolicy> onEdit;
  final ValueChanged<LeaveTypePolicy> onRemove;

  @override
  Widget build(BuildContext context) {
    final error = showActionError ? controller.actionErrorMessage : null;
    final busy = controller.isSavingType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          ErrorBanner(message: error, onDismiss: controller.clearActionError),
          const SizedBox(height: AppSpacing.md),
        ],
        SettingsSwitchTile(
          value: policy.monthlyAccrual,
          onChanged: controller.isUpdatingAccrual ? null : onAccrualChanged,
          title: 'Accrue leave monthly',
          subtitle: 'On: 1/12 of each yearly allowance becomes available every month, and unused days carry to later months. Off: the whole allowance is available from January.',
        ),
        const Divider(height: 1, color: AppColors.outlineSubtle),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Leave types',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            AppButton.outlined(
              text: 'Add leave type',
              iconData: Icons.add,
              isFullWidth: false,
              onPressed: busy ? null : onAdd,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final type in policy.leaveTypes)
          LeaveTypeTile(
            leaveType: type,
            onEdit: () => onEdit(type),
            onRemove: () => onRemove(type),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Approved leave within the remaining allowance is paid; days beyond '
          'it are unpaid and deducted from salary. Allowances are pro-rated '
          'from each employee\'s joining month. Unused days lapse on '
          '31 December unless the type carries forward. A new allowance '
          'applies from the next month and the accrual setting from today; '
          'earlier months and past payroll are not affected.',
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}
