import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

/// Screen displayed when an organization is suspended or undergoing maintenance.
/// Designed to match Stitch Design: "Organization Unavailable - Phone".
class OrganizationUnavailablePage extends StatelessWidget {
  const OrganizationUnavailablePage({super.key});

  void _showSupportDialog(BuildContext context, String orgName) {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The workspace for "$orgName" is temporarily restricted. Please contact your organization owner or WorkAxis Support for more details.',
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
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

    String orgName = 'The organization';
    bool hasOtherOrgs = false;

    if (state is OrganizationUnavailableState) {
      orgName = state.organization.name;
      hasOtherOrgs = state.otherMemberships.isNotEmpty;
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
                      Icons.domain_disabled_rounded,
                      size: 48,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    'Organization suspended',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Message
                  Text(
                    'The organization "$orgName" is currently unavailable. Please contact support if you believe this is an error.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Primary Action
                  if (hasOtherOrgs) ...[
                    AppButton(
                      text: 'Choose Another Organization',
                      onPressed: () => context.go('/organizations'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: AppSpacing.touchTarget,
                      child: FilledButton.tonal(
                        onPressed: () => _showSupportDialog(context, orgName),
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
                    SizedBox(
                      width: double.infinity,
                      height: AppSpacing.touchTarget,
                      child: TextButton(
                        onPressed: () async {
                          await context.read<AuthController>().signOut();
                          if (context.mounted) {
                            orgController.clear();
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
                  ] else ...[
                    AppButton(
                      text: 'Contact Support',
                      onPressed: () => _showSupportDialog(context, orgName),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: AppSpacing.touchTarget,
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await context.read<AuthController>().signOut();
                          if (context.mounted) {
                            orgController.clear();
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
