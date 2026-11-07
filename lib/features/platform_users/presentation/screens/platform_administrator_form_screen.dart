import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_profile_fields.dart';

class PlatformAdministratorFormScreen extends StatefulWidget {
  const PlatformAdministratorFormScreen({
    super.key,
    this.administratorId,
    this.now = systemNow,
  });

  final String? administratorId;

  /// Clock used to stamp the draft's creation time.
  final Now now;

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
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
    } else {
      _profileLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<PlatformUsersController>().clearActionError();
      });
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
    if (!mounted) return;
    final controller = context.read<PlatformUsersController>()
      ..clearActionError();
    final administrator = await controller.loadAdministrator(
      widget.administratorId!,
    );
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
    final confirmation = _confirmPasswordController.text;
    final password = _passwordController.text;

    setState(() {
      _nameError = name.isEmpty ? 'Enter the administrator’s full name.' : null;
      _usernameError = widget.isEditing
          ? null
          : ContactValidators.username(_usernameController.text);
      _emailError = ContactValidators.optionalEmail(_emailController.text);
      _phoneError = ContactValidators.optionalPhone(_phoneController.text);
      _passwordError = widget.isEditing
          ? null
          : ContactValidators.password(password);
      _confirmPasswordError = !widget.isEditing && confirmation != password
          ? 'Passwords do not match.'
          : null;
    });
    return _nameError == null &&
        _usernameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final controller = context.read<PlatformUsersController>()
      ..clearActionError();
    final normalizedPhone = ContactValidators.normalizePhone(
      _phoneController.text,
    );
    final email = _emailController.text.trim().toLowerCase();
    PlatformAdministrator? saved;

    if (widget.isEditing) {
      final current = controller.selectedAdministrator;
      if (current == null) {
        _toast('This administrator is no longer loaded. Go back and retry.');
        return;
      }
      saved = await controller.updateAdministrator(
        current.copyWith(
          fullName: _nameController.text.trim(),
          email: email,
          phone: normalizedPhone,
          clearPhone: normalizedPhone == null,
        ),
      );
    } else {
      saved = await controller.createAdministrator(
        administrator: PlatformAdministrator(
          id: 'new-platform-administrator',
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim().toLowerCase(),
          email: email,
          phone: normalizedPhone,
          status: AccountStatus.active,
          createdAt: widget.now(),
        ),
        initialPassword: _passwordController.text,
      );
    }

    if (!mounted) return;
    if (saved == null) {
      // The banner above the form shows the reason; scroll position may hide
      // it, so also announce the failure.
      _toast(
        controller.actionErrorMessage ??
            'The administrator could not be saved. Try again.',
      );
      return;
    }
    _passwordController.clear();
    _confirmPasswordController.clear();
    _toast(
      widget.isEditing
          ? '${saved.fullName} updated.'
          : '${saved.fullName} added as a Platform Administrator.',
    );
    context.go(AppRoutes.platformUserDetailsPath(saved.id));
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformUsersController>();
    final isCompact = context.isCompact;
    final current = controller.selectedAdministrator;
    final currentMatches = current?.id == widget.administratorId;

    if (!_profileLoaded || (widget.isEditing && !currentMatches)) {
      if (_profileLoaded && !controller.isLoading) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ErrorState(
                  message:
                      controller.errorMessage ??
                      'This platform administrator could not be found.',
                  onRetry: _loadProfile,
                ),
                AppButton.outlined(
                  text: 'Back to Platform Users',
                  isFullWidth: false,
                  onPressed: () => context.go(AppRoutes.platformUsers),
                ),
              ],
            ),
          ),
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
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton.outlined(
                      text: 'Platform Users',
                      iconData: Icons.arrow_back,
                      isFullWidth: false,
                      onPressed: () => context.go(AppRoutes.platformUsers),
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
                    ErrorBanner(
                      message: controller.actionErrorMessage!,
                      onDismiss: controller.clearActionError,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const PlatformAdministratorRoleNote(),
                  const SizedBox(height: AppSpacing.md),
                  PlatformAdministratorProfileFields(
                    nameController: _nameController,
                    usernameController: _usernameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    nameError: _nameError,
                    usernameError: _usernameError,
                    emailError: _emailError,
                    phoneError: _phoneError,
                    usernameEnabled: !widget.isEditing,
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
