import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';

enum AppButtonVariant { primary, secondaryTonal, outlined }

/// Canonical, responsive Material 3 Button template.
///
/// Features:
/// - 48dp minimum touch target adhering to Material 3 accessibility guidelines.
/// - Adaptive sizing: full-width on smartphone, auto/intrinsic-width on tablet and desktop.
/// - Primary, Secondary (Tonal), and Outlined variants.
/// - Built-in loading indicator state.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool? isFullWidth;
  final bool isAdaptive;

  AppButton({
    super.key,
    String? text,
    String? label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    Widget? icon,
    IconData? iconData,
    this.isFullWidth = true,
    this.isAdaptive = false,
  }) : text = text ?? label ?? '',
       icon = icon ?? (iconData != null ? Icon(iconData, size: 18) : null);

  /// Convenient primary button template.
  factory AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    IconData? iconData,
    bool isFullWidth = true,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: AppButtonVariant.primary,
    isLoading: isLoading,
    icon: icon,
    iconData: iconData,
    isFullWidth: isFullWidth,
  );

  /// Convenient secondary tonal button template.
  factory AppButton.secondary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    IconData? iconData,
    bool isFullWidth = true,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: AppButtonVariant.secondaryTonal,
    isLoading: isLoading,
    icon: icon,
    iconData: iconData,
    isFullWidth: isFullWidth,
  );

  /// Convenient outlined button template.
  factory AppButton.outlined({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    IconData? iconData,
    bool isFullWidth = true,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: AppButtonVariant.outlined,
    isLoading: isLoading,
    icon: icon,
    iconData: iconData,
    isFullWidth: isFullWidth,
  );

  /// Adaptive button template: automatically full-width on smartphone (< 600dp)
  /// and intrinsic/compact width on tablet and desktop.
  factory AppButton.responsive({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    AppButtonVariant variant = AppButtonVariant.primary,
    bool isLoading = false,
    Widget? icon,
    IconData? iconData,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: variant,
    isLoading: isLoading,
    icon: icon,
    iconData: iconData,
    isAdaptive: true,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final effectiveFullWidth = isAdaptive
        ? context.isCompact
        : (isFullWidth ?? true);

    return LayoutBuilder(
      builder: (context, constraints) {
        final renderFullWidth =
            effectiveFullWidth && constraints.hasBoundedWidth;

        final childContent = Row(
          mainAxisSize: renderFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ] else if (icon != null) ...[
              icon!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _textColor(context),
                ),
              ),
            ),
          ],
        );

        final minSize = Size(
          renderFullWidth ? double.infinity : AppSpacing.minButtonWidth,
          AppSpacing.minTouchTarget,
        );

        Widget button;
        switch (variant) {
          case AppButtonVariant.primary:
            button = FilledButton(
              onPressed: effectiveOnPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: minSize,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedSm,
                ),
              ),
              child: childContent,
            );
            break;
          case AppButtonVariant.secondaryTonal:
            button = FilledButton.tonal(
              onPressed: effectiveOnPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                minimumSize: minSize,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedSm,
                ),
              ),
              child: childContent,
            );
            break;
          case AppButtonVariant.outlined:
            button = OutlinedButton(
              onPressed: effectiveOnPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.outlineVariant),
                minimumSize: minSize,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedSm,
                ),
              ),
              child: childContent,
            );
            break;
        }

        return button;
      },
    );
  }

  Color _textColor(BuildContext context) {
    if (onPressed == null && !isLoading) {
      return AppColors.textMuted;
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.onPrimary;
      case AppButtonVariant.secondaryTonal:
        return AppColors.onPrimaryContainer;
      case AppButtonVariant.outlined:
        return AppColors.primary;
    }
  }
}
