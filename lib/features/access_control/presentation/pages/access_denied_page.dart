import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

/// Screen displayed when an authenticated user is not present in the `users` collection
/// or does not have authorization to access the application.
/// Designed to match Stitch Design: "Access Denied - Phone".
class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

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
                'Please reach out to your organization administrator or HR department to request access.',
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
    final orgController = context.watch<OrganizationContextController>();
    final state = orgController.state;

    String reason =
        'Your sign-in was successful, but this account has not been granted access to the application.';
    if (state is AccessDeniedState && state.reason.isNotEmpty) {
      reason = state.reason;
    }

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
                  // Lock Icon in Error Container
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 48,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Headline
                  Text(
                    'You do not have access',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Subtitle / Description
                  Text(
                    reason,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Actions
                  // 1. Try Another Account (Primary Filled)
                  AppButton(
                    text: 'Try Another Account',
                    onPressed: () async {
                      await context.read<AuthController>().signOut();
                      if (context.mounted) {
                        context.read<OrganizationContextController>().clear();
                        context.go('/signin/phone');
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Contact Support (Tonal Button)
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.touchTarget,
                    child: FilledButton.tonal(
                      onPressed: () => _showSupportDialog(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        foregroundColor: AppColors.primary,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Contact Support',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // 3. Sign Out (Text Button)
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.touchTarget,
                    child: TextButton(
                      onPressed: () async {
                        await context.read<AuthController>().signOut();
                        if (context.mounted) {
                          context.read<OrganizationContextController>().clear();
                          context.go('/welcome');
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
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
