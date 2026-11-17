import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Asks before suspending or restoring [member]. Resolves to true only when
/// the user confirms.
Future<bool> confirmMemberStatusChange(
  BuildContext context, {
  required OrganizationMember member,
  required bool suspend,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        suspend ? 'Suspend ${member.fullName}?' : 'Restore ${member.fullName}?',
      ),
      content: Text(
        suspend
            ? '${member.fullName} will no longer be able to sign in. '
                  'You can restore access later.'
            : 'Allow ${member.fullName} to sign in again?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: suspend
                ? AppColors.statusUrgentText
                : AppColors.primary,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(suspend ? 'Suspend' : 'Restore'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Asks before permanently deleting [member]. Resolves to true only when the
/// user confirms.
Future<bool> confirmMemberDelete(
  BuildContext context, {
  required OrganizationMember member,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete ${member.fullName}?'),
      content: const Text(
        'The account is removed for good and can no longer sign in. An account '
        'with return or attendance records cannot be deleted; suspend it instead.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.statusUrgentText,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Asks for a new password for [member]. Resolves to the password, or null
/// when the user cancels.
Future<String?> showResetMemberPasswordDialog(
  BuildContext context, {
  required OrganizationMember member,
}) => showDialog<String>(
  context: context,
  builder: (_) => _ResetMemberPasswordDialog(member: member),
);

class _ResetMemberPasswordDialog extends StatefulWidget {
  const _ResetMemberPasswordDialog({required this.member});

  final OrganizationMember member;

  @override
  State<_ResetMemberPasswordDialog> createState() =>
      _ResetMemberPasswordDialogState();
}

class _ResetMemberPasswordDialogState
    extends State<_ResetMemberPasswordDialog> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _password.text;
    final error =
        ContactValidators.password(password) ??
        (_confirmation.text != password ? 'Passwords do not match.' : null);
    setState(() => _error = error);
    if (error == null) Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reset password for ${widget.member.fullName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPasswordField(
            controller: _password,
            label: 'New password',
            hintText: 'At least 8 characters',
            errorText: _error,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPasswordField(
            controller: _confirmation,
            label: 'Confirm password',
            hintText: 'Re-enter the password',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Reset password')),
      ],
    );
  }
}
