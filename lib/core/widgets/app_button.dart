import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';

enum AppButtonVariant { primary, tonal, outlined, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSpacing.touchTarget,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget childContent;
    if (isLoading) {
      final spinnerColor = variant == AppButtonVariant.primary
          ? AppColors.onPrimary
          : AppColors.primary;
      childContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    } else if (icon != null) {
      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    } else {
      childContent = Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.7),
            minimumSize: Size(width ?? double.infinity, height),
            shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderFull),
            elevation: 0,
          ),
          child: childContent,
        );
      case AppButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.surfaceContainerHigh,
            foregroundColor: AppColors.primary,
            minimumSize: Size(width ?? double.infinity, height),
            shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderFull),
            elevation: 0,
          ),
          child: childContent,
        );
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.outline, width: 1),
            minimumSize: Size(width ?? double.infinity, height),
            shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderFull),
          ),
          child: childContent,
        );
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(width ?? 48, height),
          ),
          child: childContent,
        );
    }

    return SizedBox(
      width: width,
      height: height,
      child: button,
    );
  }
}
