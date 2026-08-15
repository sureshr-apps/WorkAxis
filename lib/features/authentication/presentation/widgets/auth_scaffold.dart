import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.body,
    this.title,
    this.subtitle,
    this.showBackButton = true,
    this.onBack,
    this.bottomAction,
    super.key,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isExpanded =
                constraints.maxWidth >= AppBreakpoints.expandedMin;
            final isMedium = constraints.maxWidth >= AppBreakpoints.mediumMin;

            if (isExpanded) {
              return _buildExpandedLayout(context);
            } else if (isMedium) {
              return _buildMediumLayout(context);
            } else {
              return _buildCompactLayout(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      children: [
        if (showBackButton)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.onSurfaceVariant),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginCompact),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                body,
              ],
            ),
          ),
        ),
        if (bottomAction != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.marginCompact),
            child: bottomAction!,
          ),
      ],
    );
  }

  Widget _buildMediumLayout(BuildContext context) {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.onSurfaceVariant),
                      onPressed:
                          onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                  if (title != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title!,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  body,
                  if (bottomAction != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    bottomAction!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedLayout(BuildContext context) {
    return Row(
      children: [
        // Left Branding Panel
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
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.onPrimaryContainer,
                        borderRadius: AppRadius.borderDefault,
                      ),
                      child: const Icon(
                        Icons.workspaces_rounded,
                        color: AppColors.primary,
                        size: 28,
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
                      'Operations & Workforce Management Platform',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Seamless branch operations, shift schedules, and real-time attendance across your organization.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
                Text(
                  'Market Flow M3 • Enterprise Edition',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            AppColors.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ),
        // Right Form Canvas
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.marginExpanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.onSurfaceVariant),
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                    if (title != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        title!,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    body,
                    if (bottomAction != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      bottomAction!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
