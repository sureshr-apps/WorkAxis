import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/shared/widgets/form_page_shell.dart';

/// Sets a new password for a platform administrator. The password is
/// validated before [onSubmit] runs; [onSubmit] resolves to an error message,
/// or null on success. The page reports through [onClose] and [onSaved].
class ResetAdministratorPasswordPage extends StatefulWidget {
  const ResetAdministratorPasswordPage({
    super.key,
    required this.administrator,
    required this.onSubmit,
    required this.onClose,
    required this.onSaved,
  });

  final PlatformAdministrator administrator;
  final Future<String?> Function(String newPassword) onSubmit;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  @override
  State<ResetAdministratorPasswordPage> createState() =>
      _ResetAdministratorPasswordPageState();
}

class _ResetAdministratorPasswordPageState
    extends State<ResetAdministratorPasswordPage> {
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
      setState(() => _isSaving = false);
      widget.onSaved();
      return;
    }
    setState(() {
      _isSaving = false;
      _submitError = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormPageShell(
      backLabel: 'Platform Users',
      currentLabel: widget.administrator.fullName,
      eyebrow: 'Platform Access',
      title: 'Reset password',
      submitLabel: 'Reset password',
      onClose: widget.onClose,
      onSubmit: _submit,
      isBusy: _isSaving,
      errorMessage: _submitError,
      body: Column(
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
            enabled: !_isSaving,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPasswordField(
            controller: _confirmation,
            label: 'Confirm password',
            hintText: 'Re-enter the new password',
            errorText: _confirmationError,
            enabled: !_isSaving,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
    );
  }
}
