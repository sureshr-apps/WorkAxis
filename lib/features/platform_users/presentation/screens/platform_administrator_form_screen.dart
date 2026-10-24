import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_profile_fields.dart';

class PlatformAdministratorFormScreen extends StatefulWidget {
  const PlatformAdministratorFormScreen({super.key, this.administratorId});

  final String? administratorId;

  bool get isEditing => administratorId != null;

  @override
  State<PlatformAdministratorFormScreen> createState() =>
      _PlatformAdministratorFormScreenState();
}

class _PlatformAdministratorFormScreenState
    extends State<PlatformAdministratorFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _profileLoaded = false;
  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
    } else {
      _profileLoaded = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final administrator = await context
        .read<PlatformUsersController>()
        .loadAdministrator(widget.administratorId!);
    if (!mounted) return;
    if (administrator != null) {
      _nameController.text = administrator.fullName;
      _usernameController.text = administrator.username;
      _emailController.text = administrator.email;
      _phoneController.text = administrator.phone ?? '';
    }
    setState(() => _profileLoaded = true);
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    setState(() {
      _nameError = name.isEmpty ? 'Enter the administrator’s full name.' : null;
      _usernameError = username.isEmpty
          ? 'Choose a username.'
          : !RegExp(r'^[a-zA-Z0-9._-]{3,32}$').hasMatch(username)
          ? 'Use 3–32 letters, numbers, dots, underscores, or hyphens.'
          : null;
      _emailError = email.isEmpty
          ? 'Enter a work email address.'
          : !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
          ? 'Enter a valid email address.'
          : null;
      _passwordError = !widget.isEditing && password.length < 8
          ? 'Use at least 8 characters.'
          : null;
      _confirmPasswordError = !widget.isEditing && confirmation != password
          ? 'Passwords do not match.'
          : null;
    });
    return _nameError == null &&
        _usernameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final controller = context.read<PlatformUsersController>();
    controller.clearActionError();
    final normalizedPhone = _phoneController.text.trim();
    PlatformAdministrator? saved;

    if (widget.isEditing) {
      final current = controller.selectedAdministrator;
      if (current == null) return;
      saved = await controller.updateAdministrator(
        current.copyWith(
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          phone: normalizedPhone,
          clearPhone: normalizedPhone.isEmpty,
        ),
      );
    } else {
      saved = await controller.createAdministrator(
        administrator: PlatformAdministrator(
          id: 'new-platform-administrator',
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          phone: normalizedPhone.isEmpty ? null : normalizedPhone,
          status: AccountStatus.active,
          createdAt: DateTime.now(),
        ),
        initialPassword: _passwordController.text,
      );
    }

    if (!mounted || saved == null) return;
    _passwordController.clear();
    _confirmPasswordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? '${saved.fullName} updated.'
              : '${saved.fullName} added as a Platform Administrator.',
        ),
      ),
    );
    context.go(AppRoutes.platformUserDetailsPath(saved.id));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformUsersController>();
    final isCompact = context.isCompact;
    final current = controller.selectedAdministrator;

    if (!_profileLoaded || (widget.isEditing && current == null)) {
      if (controller.errorMessage != null && !controller.isLoading) {
        return _LoadError(
          message: controller.errorMessage!,
          onBack: () => context.go(AppRoutes.platformUsers),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.platformUsers),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Platform Users'),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(48, 48),
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppPageHeader(
                    eyebrow: 'Platform Access',
                    title: widget.isEditing
                        ? 'Edit Platform Administrator'
                        : 'Add Platform Administrator',
                    subtitle: widget.isEditing
                        ? 'Update profile and sign-in identifiers.'
                        : 'Create an administrator account for platform operations.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (controller.actionErrorMessage != null) ...[
                    _SubmissionError(message: controller.actionErrorMessage!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  PlatformAdministratorRoleNote(),
                  const SizedBox(height: AppSpacing.md),
                  PlatformAdministratorProfileFields(
                    nameController: _nameController,
                    usernameController: _usernameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    nameError: _nameError,
                    usernameError: _usernameError,
                    emailError: _emailError,
                  ),
                  if (!widget.isEditing) ...[
                    const SizedBox(height: AppSpacing.md),
                    PlatformAdministratorCredentialsFields(
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      passwordError: _passwordError,
                      confirmPasswordError: _confirmPasswordError,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _FormActions(
                    isCompact: isCompact,
                    isSaving: controller.isSaving,
                    editing: widget.isEditing,
                    onCancel: () => context.go(AppRoutes.platformUsers),
                    onSave: _save,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormActions extends StatelessWidget {
  const _FormActions({
    required this.isCompact,
    required this.isSaving,
    required this.editing,
    required this.onCancel,
    required this.onSave,
  });

  final bool isCompact;
  final bool isSaving;
  final bool editing;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cancel = AppButton.outlined(
      text: 'Cancel',
      onPressed: isSaving ? null : onCancel,
      isFullWidth: isCompact,
    );
    final save = AppButton.primary(
      text: editing ? 'Save Changes' : 'Create Administrator',
      onPressed: onSave,
      isLoading: isSaving,
      isFullWidth: isCompact,
    );
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cancel,
          const SizedBox(height: AppSpacing.sm),
          save,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        cancel,
        const SizedBox(width: AppSpacing.sm),
        save,
      ],
    );
  }
}

class _SubmissionError extends StatelessWidget {
  const _SubmissionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusUrgentContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.statusUrgentBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusUrgent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.statusUrgentText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              AppButton.outlined(
                text: 'Back to Platform Users',
                onPressed: onBack,
                isFullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
