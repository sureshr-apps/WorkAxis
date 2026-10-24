import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';

class OrganizationAdminDraft {
  const OrganizationAdminDraft({
    required this.administrator,
    required this.initialPassword,
  });

  final OrganizationAdminUser administrator;
  final String initialPassword;
}

class OrganizationAdminDialog extends StatefulWidget {
  const OrganizationAdminDialog({super.key, this.existingAdministrator});

  final OrganizationAdminUser? existingAdministrator;

  @override
  State<OrganizationAdminDialog> createState() =>
      _OrganizationAdminDialogState();
}

class _OrganizationAdminDialogState extends State<OrganizationAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  String? _errorMessage;

  bool get _isEditing => widget.existingAdministrator != null;

  @override
  void initState() {
    super.initState();
    final admin = widget.existingAdministrator;
    _nameController = TextEditingController(text: admin?.name ?? '');
    _usernameController = TextEditingController(
      text: admin?.username ?? admin?.email.split('@').first ?? '',
    );
    _emailController = TextEditingController(text: admin?.email ?? '');
    _phoneController = TextEditingController(text: admin?.phone ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().replaceFirst('@', '');
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final validEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (name.isEmpty || username.isEmpty || !validEmail || phone.isEmpty) {
      setState(
        () => _errorMessage =
            'Enter a name, username, valid email, and phone number.',
      );
      return;
    }
    if (!_isEditing && password.trim().length < 8) {
      setState(
        () =>
            _errorMessage = 'Set an initial password of at least 8 characters.',
      );
      return;
    }

    final existing = widget.existingAdministrator;
    Navigator.of(context).pop(
      OrganizationAdminDraft(
        administrator: OrganizationAdminUser(
          id: existing?.id ?? 'admin-${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          username: username,
          email: email,
          phone: phone,
          roleTitle: existing?.roleTitle ?? 'Tenant Administrator',
          status: existing?.status ?? 'Active',
          lastLogin: existing?.lastLogin,
        ),
        initialPassword: password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEditing ? 'Edit Administrator' : 'Add Administrator',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Administrator credentials stay in memory only during this mock session.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _nameController,
                    label: 'Full name',
                    hintText: 'Enter full name',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hintText: 'Enter username',
                    prefixIcon: const Icon(Icons.alternate_email, size: 18),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email address',
                    hintText: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone number',
                    hintText: 'Enter phone number',
                    keyboardType: TextInputType.phone,
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppPasswordField(
                      controller: _passwordController,
                      label: 'Initial password',
                      hintText: 'At least 8 characters',
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.statusUrgentText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: _submit,
                        child: Text(
                          _isEditing ? 'Save Changes' : 'Add Administrator',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
