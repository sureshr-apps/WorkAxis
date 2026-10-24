import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';

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
  });

  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final String? nameError;
  final String? usernameError;
  final String? emailError;

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Administrator profile',
      subtitle: 'Contact details and sign-in aliases for this account.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = context.isCompact ? 1 : 2;
          final gap = AppSpacing.md;
          final fieldWidth = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - gap) / 2;
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
                  textInputAction: TextInputAction.next,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: AppTextField(
                  controller: emailController,
                  label: 'Work email *',
                  hintText: 'name@workaxis.example',
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
                  hintText: 'Optional',
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
    return _FormSection(
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
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        context.isCompact ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x04000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
