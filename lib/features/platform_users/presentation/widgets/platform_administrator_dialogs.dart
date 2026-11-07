import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_dialog_frame.dart';

/// Asks the user to confirm suspending or restoring [administrator]'s access.
/// Resolves to true only when the user confirms.
Future<bool> confirmAdministratorStatusChange(
  BuildContext context, {
  required PlatformAdministrator administrator,
  required AccountStatus nextStatus,
}) async {
  final suspend = nextStatus == AccountStatus.suspended;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => PlatformDialogFrame(
      title: suspend ? 'Suspend access?' : 'Restore access?',
      body: Text(
        suspend
            ? '${administrator.fullName} will no longer be able to sign in. '
                  'You can restore access later.'
            : 'Allow ${administrator.fullName} to sign in to WorkAxis again?',
      ),
      actions: [
        AppButton.outlined(
          text: 'Cancel',
          isFullWidth: false,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppButton(
          variant: suspend
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          text: suspend ? 'Suspend access' : 'Restore access',
          isFullWidth: false,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Prompts for a new password for [administrator]. Resolves to the password,
/// or null when cancelled. The password is validated before the dialog closes.
Future<String?> promptAdministratorPasswordReset(
  BuildContext context, {
  required PlatformAdministrator administrator,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ResetPasswordDialog(administrator: administrator),
  );
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.administrator});

  final PlatformAdministrator administrator;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _passwordError;
  String? _confirmationError;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    final passwordError = ContactValidators.password(_password.text);
    final confirmationError = _confirmation.text != _password.text
        ? 'Passwords do not match.'
        : null;
    if (passwordError != null || confirmationError != null) {
      setState(() {
        _passwordError = passwordError;
        _confirmationError = confirmationError;
      });
      return;
    }
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformDialogFrame(
      title: 'Reset password',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set a new password for ${widget.administrator.fullName}. '
            'They can change it after signing in.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppPasswordField(
            controller: _password,
            label: 'New password',
            hintText: 'At least 8 characters',
            errorText: _passwordError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPasswordField(
            controller: _confirmation,
            label: 'Confirm password',
            hintText: 'Re-enter the new password',
            errorText: _confirmationError,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        AppButton.outlined(
          text: 'Cancel',
          isFullWidth: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          text: 'Reset password',
          isFullWidth: false,
          onPressed: _submit,
        ),
      ],
    );
  }
}
