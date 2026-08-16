import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

/// Screen displayed when an employee/manager account is active but has no branch assigned.
/// Designed to match Stitch Design: "Branch Assignment Required - Phone".
class BranchAssignmentRequiredPage extends StatefulWidget {
  const BranchAssignmentRequiredPage({super.key});

  @override
  State<BranchAssignmentRequiredPage> createState() =>
      _BranchAssignmentRequiredPageState();
}

class _BranchAssignmentRequiredPageState
    extends State<BranchAssignmentRequiredPage> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final orgController = context.read<OrganizationContextController>();
    await orgController.retryResolution();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _showContactAdminDialog(BuildContext context, String orgName) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          title: const Text(
            'Contact Administrator',
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
                'Please reach out to your $orgName administrator to assign you to a branch store or warehouse location.',
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  Icon(Icons.email_outlined,
                      size: 20, color: AppColors.primary),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'admin@workaxis.io',
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

    String orgName = 'your organization';
    bool hasMultipleOrgs = false;

    if (state is BranchAssignmentRequiredState) {
      orgName = state.membership.organization.name;
      hasMultipleOrgs = state.allMemberships.length > 1;
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
                  // Illustration Anchor: SurfaceContainerHigh circle with outline & glow
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.errorContainer.withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.domain_disabled_rounded,
                      size: 40,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    'Branch assignment required',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Message
                  Text(
                    'Your account is active with $orgName, but no branch is currently assigned. Contact your organization administrator.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Action 1: Refresh (Primary Filled with refresh icon)
                  AppButton(
                    text: 'Refresh',
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    isLoading: _isRefreshing,
                    onPressed: _handleRefresh,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Action 2: Contact Administrator (Tonal Button with support icon)
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.touchTarget,
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          _showContactAdminDialog(context, orgName),
                      icon: const Icon(Icons.support_agent_rounded, size: 20),
                      label: const Text(
                        'Contact Administrator',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        foregroundColor: AppColors.primary,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Action 3: Switch Org / Sign Out (Text Button)
                  if (hasMultipleOrgs) ...[
                    SizedBox(
                      width: double.infinity,
                      height: AppSpacing.touchTarget,
                      child: TextButton.icon(
                        onPressed: () => context.go('/organizations'),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                        label: const Text(
                          'Switch Organization',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.touchTarget,
                    child: TextButton.icon(
                      onPressed: () async {
                        await context.read<AuthController>().signOut();
                        if (context.mounted) {
                          orgController.clear();
                          context.go('/welcome');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        shape: const StadiumBorder(),
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
