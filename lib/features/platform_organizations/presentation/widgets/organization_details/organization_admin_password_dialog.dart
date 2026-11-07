import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_dialog_frame.dart';

/// Sets a new password for an Organization Administrator.
///
/// [onSubmit] resolves to an error message, or null on success. The password
/// lives only in the text controllers and is never stored.
class OrganizationAdminPasswordDialog extends StatefulWidget {
  const OrganizationAdminPasswordDialog({
    super.key,
    required this.administrator,
    required this.onSubmit,
  });

  final OrganizationAdminUser administrator;
  final Future<String?> Function(String newPassword) onSubmit;

  @override
  State<OrganizationAdminPasswordDialog> createState() =>
      _OrganizationAdminPasswordDialogState();
}

class _OrganizationAdminPasswordDialogState
    extends State<OrganizationAdminPasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _passwordError;
  String? _confirmationError;
  String? _submitError;
  bool _isSaving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final passwordError = ContactValidators.password(_password.text);
    final confirmationError = _confirmation.text != _password.text
        ? 'Passwords do not match.'
        : null;
    if (passwordError != null || confirmationError != null) {
      setState(() {
        _passwordError = passwordError;
        _confirmationError = confirmationError;
        _submitError = null;
      });
      return;
    }
    setState(() {
      _passwordError = null;
      _confirmationError = null;
      _submitError = null;
      _isSaving = true;
    });
    final failure = await widget.onSubmit(_password.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSaving = false;
      _submitError = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: PlatformDialogFrame(
        title: 'Reset password',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set a new password for ${widget.administrator.name}. They can '
              'change it after signing in.',
              style: AppTypography.bodySmall,
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
            if (_submitError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(
                liveRegion: true,
                child: Text(
                  _submitError!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.statusUrgentText,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          AppButton.outlined(
            text: 'Cancel',
            isFullWidth: false,
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          ),
          AppButton.primary(
            text: 'Reset password',
            isFullWidth: false,
            isLoading: _isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
