import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_draft.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_admin_rules.dart';
import 'package:workaxis/shared/widgets/form_page_shell.dart';

/// Saves a draft; resolves to an error message, or null on success.
typedef OrganizationAdminSubmit = Future<String?> Function(
  OrganizationAdminDraft draft,
);

/// Add or edit an Organization Administrator.
///
/// Email and phone are optional login aliases and are validated only when
/// provided. Field errors are shown per field; a failed save keeps the page
/// open with the entered values. The page only reports: [onClose] for back and
/// cancel, [onSaved] after a successful save.
class OrganizationAdminFormPage extends StatefulWidget {
  const OrganizationAdminFormPage({
    super.key,
    required this.backLabel,
    required this.onSubmit,
    required this.onClose,
    required this.onSaved,
    this.existingAdministrator,
  });

  /// Name of the organization page the back link returns to.
  final String backLabel;
  final OrganizationAdminSubmit onSubmit;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final OrganizationAdminUser? existingAdministrator;

  @override
  State<OrganizationAdminFormPage> createState() =>
      _OrganizationAdminFormPageState();
}

class _OrganizationAdminFormPageState extends State<OrganizationAdminFormPage> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final TextEditingController _password = TextEditingController();
  Map<String, String> _errors = const {};
  String? _submitError;
  bool _isSaving = false;

  bool get _isEditing => widget.existingAdministrator != null;

  @override
  void initState() {
    super.initState();
    final admin = widget.existingAdministrator;
    _name = TextEditingController(text: admin?.name ?? '');
    _username = TextEditingController(text: admin?.username ?? '');
    _email = TextEditingController(text: admin?.email ?? '');
    _phone = TextEditingController(text: admin?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final draft = OrganizationAdminDraft(
      name: _name.text.trim(),
      username: _username.text.trim().replaceFirst('@', ''),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      initialPassword: _isEditing ? null : _password.text,
    );
    final errors = OrganizationAdminRules.fieldErrors(
      draft,
      isCreate: !_isEditing,
    );
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _submitError = null;
      });
      return;
    }
    setState(() {
      _errors = const {};
      _submitError = null;
      _isSaving = true;
    });
    final failure = await widget.onSubmit(draft);
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
      currentLabel: widget.existingAdministrator?.name ?? 'New administrator',
      eyebrow: 'Platform catalog',
      title: _isEditing ? 'Edit Administrator' : 'Add Administrator',
      submitLabel: _isEditing ? 'Save Changes' : 'Add Administrator',
      onClose: widget.onClose,
      onSubmit: _submit,
      isBusy: _isSaving,
      errorMessage: _submitError,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing
                ? 'Update the contact details. The username cannot be '
                      'changed.'
                : 'Creates a sign-in account for an administrator of this '
                      'organization. Email and phone are optional.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _name,
            label: 'Full name',
            hintText: 'Enter full name',
            errorText: _errors['name'],
            enabled: !_isSaving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _username,
            label: 'Username',
            hintText: 'Enter username',
            errorText: _errors['username'],
            enabled: !_isSaving && !_isEditing,
            prefixIcon: const Icon(Icons.alternate_email, size: 18),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _email,
            label: 'Email address (optional)',
            hintText: 'name@example.com',
            errorText: _errors['email'],
            enabled: !_isSaving,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _phone,
            label: 'Phone number (optional)',
            hintText: '+91 98765 43210',
            errorText: _errors['phone'],
            enabled: !_isSaving,
            keyboardType: TextInputType.phone,
            textInputAction: _isEditing
                ? TextInputAction.done
                : TextInputAction.next,
          ),
          if (!_isEditing) ...[
            const SizedBox(height: AppSpacing.md),
            AppPasswordField(
              controller: _password,
              label: 'Initial password',
              hintText: 'At least 8 characters',
              errorText: _errors['password'],
              onSubmitted: (_) => _submit(),
            ),
          ],
        ],
      ),
    );
  }
}
