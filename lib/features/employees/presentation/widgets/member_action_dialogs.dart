import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/async_confirmation_dialog.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Confirms the status change and waits for the request before closing.
Future<bool> confirmMemberStatusChange(
  BuildContext context, {
  required OrganizationMember member,
  required bool suspend,
  required Future<bool> Function() onConfirm,
  String? Function()? failureMessage,
}) => showAsyncConfirmationDialog(
  context: context,
  title: suspend
      ? 'Suspend ${member.fullName}?'
      : 'Restore ${member.fullName}?',
  content: Text(
    suspend
        ? '${member.fullName} will no longer be able to sign in. '
              'You can restore access later.'
        : 'Allow ${member.fullName} to sign in again?',
  ),
  confirmLabel: suspend ? 'Suspend' : 'Restore',
  destructive: suspend,
  onConfirm: onConfirm,
  failureMessage: failureMessage,
);

/// Confirms permanent deletion and waits for the request before closing.
Future<bool> confirmMemberDelete(
  BuildContext context, {
  required OrganizationMember member,
  required Future<bool> Function() onConfirm,
  String? Function()? failureMessage,
}) => showAsyncConfirmationDialog(
  context: context,
  title: 'Delete ${member.fullName}?',
  content: const Text(
    'The account is removed for good and can no longer sign in. An account '
    'with return or attendance records cannot be deleted; suspend it instead.',
  ),
  confirmLabel: 'Delete',
  destructive: true,
  onConfirm: onConfirm,
  failureMessage: failureMessage,
);

/// Collects and resets a password before closing, keeping errors in the dialog.
Future<bool> showResetMemberPasswordDialog(
  BuildContext context, {
  required OrganizationMember member,
  required Future<bool> Function(String password) onSubmit,
  String? Function()? failureMessage,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResetMemberPasswordDialog(
        member: member,
        onSubmit: onSubmit,
        failureMessage: failureMessage,
      ),
    ) ??
    false;

class _ResetMemberPasswordDialog extends StatefulWidget {
  const _ResetMemberPasswordDialog({
    required this.member,
    required this.onSubmit,
    required this.failureMessage,
  });

  final OrganizationMember member;
  final Future<bool> Function(String password) onSubmit;
  final String? Function()? failureMessage;

  @override
  State<_ResetMemberPasswordDialog> createState() =>
      _ResetMemberPasswordDialogState();
}

class _ResetMemberPasswordDialogState
    extends State<_ResetMemberPasswordDialog> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();
  String? _error;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final password = _password.text;
    final validationError =
        ContactValidators.password(password) ??
        (_confirmation.text != password ? 'Passwords do not match.' : null);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    var succeeded = false;
    try {
      succeeded = await widget.onSubmit(password);
    } catch (_) {
      succeeded = false;
    }
    if (!mounted) return;
    if (succeeded) {
      Navigator.of(context).pop(true);
      return;
    }

    final failure = widget.failureMessage?.call()?.trim();
    setState(() {
      _isSubmitting = false;
      _error = failure == null || failure.isEmpty
          ? 'The password could not be reset. Try again.'
          : failure;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isSubmitting,
    child: AlertDialog(
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
        AppButton.outlined(
          text: 'Cancel',
          isFullWidth: false,
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
        ),
        AppButton.primary(
          text: 'Reset password',
          isFullWidth: false,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    ),
  );
}
