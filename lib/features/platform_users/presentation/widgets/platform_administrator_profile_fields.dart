import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_users_panel.dart';

class PlatformAdministratorProfileFields extends StatelessWidget {
  const PlatformAdministratorProfileFields({
    super.key,
    required this.nameController,
    required this.usernameController,
    required this.emailController,
    required this.phoneController,
    this.nameError,
    this.usernameError,
    this.emailError,
    this.phoneError,
    this.usernameEnabled = true,
  });

  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final String? nameError;
  final String? usernameError;
  final String? emailError;
  final String? phoneError;

  /// The username is fixed once the account exists.
  final bool usernameEnabled;

  @override
  Widget build(BuildContext context) {
    return PlatformUsersPanel(
      title: 'Administrator profile',
      subtitle: 'Contact details and sign-in aliases for this account.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpacing.md;
          final fieldWidth = constraints.maxWidth >= AppBreakpoints.formSplit
              ? (constraints.maxWidth - gap) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: gap,
            runSpacing: AppSpacing.md,
            children: [
              SizedBox(
                width: fieldWidth,
                child: AppTextField(
                  controller: nameController,
                  label: 'Full name *',
                  hintText: 'Enter the administrator name',
                  errorText: nameError,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: AppTextField(
                  controller: usernameController,
                  label: 'Username *',
                  hintText: 'For example, jsmith',
                  errorText: usernameError,
                  enabled: usernameEnabled,
                  textInputAction: TextInputAction.next,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: AppTextField(
                  controller: emailController,
                  label: 'Work email',
                  hintText: 'Optional, name@workaxis.example',
                  errorText: emailError,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: AppTextField(
                  controller: phoneController,
                  label: 'Phone number',
                  hintText: 'Optional, e.g. +91 98765 43210',
                  errorText: phoneError,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PlatformAdministratorCredentialsFields extends StatelessWidget {
  const PlatformAdministratorCredentialsFields({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    this.passwordError,
    this.confirmPasswordError,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? passwordError;
  final String? confirmPasswordError;

  @override
  Widget build(BuildContext context) {
    return PlatformUsersPanel(
      title: 'Sign-in credentials',
      subtitle: 'Set an initial password for the new account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPasswordField(
            controller: passwordController,
            label: 'Initial password *',
            hintText: 'At least 8 characters',
            errorText: passwordError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPasswordField(
            controller: confirmPasswordController,
            label: 'Confirm password *',
            hintText: 'Re-enter the initial password',
            errorText: confirmPasswordError,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The account creator sets the initial password. It will not be shown again.',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class PlatformAdministratorRoleNote extends StatelessWidget {
  const PlatformAdministratorRoleNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Role: Platform Administrator. Platform Owners are the only users who can manage platform accounts.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
