import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= AppBreakpoints.expandedMin) {
              return _buildExpandedWelcome(context);
            } else if (constraints.maxWidth >= AppBreakpoints.mediumMin) {
              return _buildMediumWelcome(context);
            } else {
              return _buildCompactWelcome(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCompactWelcome(BuildContext context) {
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();
    final isLoading = authController.state is AuthAuthenticating;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginCompact,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          const Spacer(),
          // Brand Logo
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.borderLg,
            ),
            child: const Icon(
              Icons.workspaces_rounded,
              color: AppColors.onPrimaryContainer,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'WorkAxis',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enterprise Workforce & Operations',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Value Propositions
          _buildValueProps(context),
          const Spacer(),
          // Action Buttons
          AppButton(
            text: 'Sign in with Phone',
            icon: const Icon(Icons.phone_iphone_rounded, size: 20),
            onPressed: () => context.push('/signin/phone'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: 'Continue with Google',
            icon: const Icon(Icons.account_circle_rounded, size: 20),
            variant: AppButtonVariant.tonal,
            isLoading: isLoading,
            onPressed: () async {
              await context.read<AuthController>().signInWithGoogle();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'By continuing, you agree to our Terms of Service & Privacy Policy.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumWelcome(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMedium),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderLg,
              side: BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _buildWelcomeContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedWelcome(BuildContext context) {
    return Row(
      children: [
        // Left Branding Showcase
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primaryContainer,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.onPrimaryContainer,
                        borderRadius: AppRadius.borderDefault,
                      ),
                      child: const Icon(
                        Icons.workspaces_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'WorkAxis',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streamlined Workforce Management for Multi-Branch Operations',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Real-time attendance, roster tracking, and organizational compliance in high-velocity environments.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
                Text(
                  'Market Flow M3 • Enterprise Operations',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            AppColors.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ),
        // Right Action Card
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.marginExpanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildWelcomeContent(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeContent(BuildContext context) {
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();
    final isLoading = authController.state is AuthAuthenticating;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppRadius.borderDefault,
              ),
              child: const Icon(
                Icons.workspaces_rounded,
                color: AppColors.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WorkAxis',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Enterprise Portal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Sign in to your organization',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Access branch rosters, shift schedules, and operational dashboards.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildValueProps(context),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          text: 'Sign in with Phone Number',
          icon: const Icon(Icons.phone_iphone_rounded, size: 20),
          onPressed: () => context.push('/signin/phone'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          text: 'Continue with Google',
          icon: const Icon(Icons.account_circle_rounded, size: 20),
          variant: AppButtonVariant.tonal,
          isLoading: isLoading,
          onPressed: () async {
            await context.read<AuthController>().signInWithGoogle();
          },
        ),
      ],
    );
  }

  Widget _buildValueProps(BuildContext context) {
    return const Column(
      children: [
        _ValuePropItem(
          icon: Icons.speed_rounded,
          title: 'Fast Check-In',
          subtitle: 'Instant geofence-verified check-ins for floor staff.',
        ),
        SizedBox(height: AppSpacing.sm),
        _ValuePropItem(
          icon: Icons.shield_rounded,
          title: 'Organization Scoped',
          subtitle: 'Multi-tenant role boundaries and branch permissions.',
        ),
        SizedBox(height: AppSpacing.sm),
        _ValuePropItem(
          icon: Icons.devices_rounded,
          title: 'Phone & Tablet Ready',
          subtitle: 'Adaptive experience across mobile and warehouse stations.',
        ),
      ],
    );
  }
}

class _ValuePropItem extends StatelessWidget {
  const _ValuePropItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: AppRadius.borderDefault,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
