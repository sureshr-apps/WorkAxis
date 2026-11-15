import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// Standard Material 3 outlined picker field styled identically to [AppTextField].
///
/// Features an external field label, [InputDecorator] matching the ambient theme,
/// custom prefix/suffix icons, and an optional clear button.
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    this.label,
    this.valueText,
    this.hintText = 'Select',
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onClear,
    this.enabled = true,
    this.errorText,
  });

  final String? label;
  final String? valueText;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasValue = valueText != null && valueText!.isNotEmpty;

    Widget? effectiveSuffix = suffixIcon;
    if (onClear != null && hasValue) {
      effectiveSuffix = IconButton(
        icon: const Icon(Icons.clear, size: 18),
        tooltip: 'Clear',
        onPressed: onClear,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          ExcludeSemantics(
            child: Text(
              label!,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Semantics(
          label: label,
          button: true,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: AppSpacing.roundedSm,
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: hintText,
                errorText: errorText,
                prefixIcon: prefixIcon,
                suffixIcon: effectiveSuffix,
                enabled: enabled,
              ),
              child: Text(
                hasValue ? valueText! : hintText,
                style: hasValue
                    ? AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurface,
                      )
                    : AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Convenience alias for date pickers.
typedef AppDatePickerField = AppPickerField;

/// Convenience alias for time pickers.
typedef AppTimePickerField = AppPickerField;
