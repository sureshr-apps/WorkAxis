import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

/// Screen displayed when an authenticated user's status is 'disabled'.
/// Designed to match Stitch Design: "Account Disabled - Phone".
class AccountDisabledPage extends StatelessWidget {
  const AccountDisabledPage({super.key});

  void _showSupportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          title: const Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your account has been deactivated. Contact your organization administrator or WorkAxis support to reactivate your access.',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.email_outlined,
                      size: 20, color: AppColors.primary),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'support@workaxis.io',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMedium,
              vertical: AppSpacing.marginExpanded,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Error Badge
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.block_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    'Your account is disabled',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Message
                  Text(
                    'Your application access has been disabled. Contact your organization administrator for assistance.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Primary Action: Contact Support
                  AppButton(
                    text: 'Contact Support',
                    onPressed: () => _showSupportDialog(context),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Secondary Action: Sign Out (Tonal Button)
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.touchTarget,
                    child: FilledButton.tonal(
                      onPressed: () async {
                        await context.read<AuthController>().signOut();
                        if (context.mounted) {
                          context.read<OrganizationContextController>().clear();
                          context.go('/welcome');
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        foregroundColor: AppColors.primary,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
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
