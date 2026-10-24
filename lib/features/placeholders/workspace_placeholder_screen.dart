import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_container.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

/// Minimal placeholder screen confirming role-based routing and active branch scoping.
class WorkspacePlaceholderScreen extends StatelessWidget {
  const WorkspacePlaceholderScreen({
    super.key,
    required this.expectedRole,
    required this.workspaceTitle,
  });

  final UserRole expectedRole;
  final String workspaceTitle;

  Future<void> _handleSignOut(BuildContext context) async {
    final authController = context.read<AuthController>();
    final accessController = context.read<AccessController>();
    final branchController = context.read<BranchContextController>();

    await authController.signOut();
    accessController.clear();
    branchController.clear();

    if (context.mounted) {
      context.go(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final accessController = context.watch<AccessController>();
    final branchController = context.watch<BranchContextController>();

    final user = authController.currentUser;
    final accessContext = accessController.accessContext;
    final org = accessContext?.organization;
    final activeBranch = branchController.activeBranch;

    final isBranchManager = expectedRole == UserRole.branchManager;
    final canSwitchBranch =
        isBranchManager && branchController.assignedBranches.length > 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          workspaceTitle,
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ResponsiveContainer(
            maxWidth: AppBreakpoints.maxFormCardWidth,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedMd,
                side: const BorderSide(color: AppColors.outlineSubtle),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.badge_outlined,
                              color: AppColors.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Authenticated User',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                expectedRole.displayName,
                                style: AppTypography.labelMono.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const StatusChip(
                          label: 'Connected',
                          type: StatusType.active,
                          width: 96,
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.xxl),

                    // Context details
                    if (org != null) ...[
                      _buildInfoRow(
                        icon: Icons.business_rounded,
                        label: 'Organization',
                        value: '${org.name} (${org.code})',
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (activeBranch != null) ...[
                      _buildInfoRow(
                        icon: Icons.storefront_rounded,
                        label: 'Active Branch Context',
                        value:
                            '${activeBranch.branchName} (${activeBranch.branchCode})',
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ] else if (isBranchManager) ...[
                      _buildInfoRow(
                        icon: Icons.warning_amber_rounded,
                        label: 'Active Branch Context',
                        value: 'None selected',
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    _buildInfoRow(
                      icon: Icons.account_circle_outlined,
                      label: 'Account Identifier',
                      value: user?.username ?? '',
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    if (canSwitchBranch) ...[
                      AppButton(
                        text: 'Change Branch',
                        variant: AppButtonVariant.secondaryTonal,
                        icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                        onPressed: () => context.go(AppRoutes.selectBranch),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    AppButton(
                      text: 'Sign Out',
                      variant: AppButtonVariant.outlined,
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      onPressed: () => _handleSignOut(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
