import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/widgets/app_button.dart';

class AccessStateView extends StatelessWidget {
  const AccessStateView({
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.iconBackgroundColor,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.isPrimaryLoading = false,
    this.content,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color? iconBackgroundColor;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final bool isPrimaryLoading;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBg =
        iconBackgroundColor ?? iconColor.withValues(alpha: 0.12);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.marginMedium),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // State Illustration Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: effectiveBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (content != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    content!,
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  if (primaryActionText != null) ...[
                    AppButton(
                      text: primaryActionText!,
                      onPressed: onPrimaryAction,
                      isLoading: isPrimaryLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (secondaryActionText != null)
                    AppButton(
                      text: secondaryActionText!,
                      onPressed: onSecondaryAction,
                      variant: AppButtonVariant.outlined,
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
