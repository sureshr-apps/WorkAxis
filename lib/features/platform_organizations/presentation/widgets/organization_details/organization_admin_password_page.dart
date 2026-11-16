import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/shared/widgets/form_page_shell.dart';

/// Sets a new password for an Organization Administrator.
///
/// [onSubmit] resolves to an error message, or null on success. The password
/// lives only in the text controllers and is never stored. The page reports
/// through [onClose] and [onSaved].
class OrganizationAdminPasswordPage extends StatefulWidget {
  const OrganizationAdminPasswordPage({
    super.key,
    required this.backLabel,
    required this.administrator,
    required this.onSubmit,
    required this.onClose,
    required this.onSaved,
  });

  /// Name of the organization page the back link returns to.
  final String backLabel;
  final OrganizationAdminUser administrator;
  final Future<String?> Function(String newPassword) onSubmit;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  @override
  State<OrganizationAdminPasswordPage> createState() =>
      _OrganizationAdminPasswordPageState();
}

class _OrganizationAdminPasswordPageState
    extends State<OrganizationAdminPasswordPage> {
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
      backLabel: widget.backLabel,
      currentLabel: widget.administrator.name,
      eyebrow: 'Platform catalog',
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
