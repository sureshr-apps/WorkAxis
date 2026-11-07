import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// Standard Material 3 outlined text field with structured label, helper, and error states.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.counterText,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onClear,
    this.showClearButton = false,
  });

  /// Factory template for Search text fields with standard search icon prefix.
  factory AppTextField.search({
    Key? key,
    TextEditingController? controller,
    String hintText = 'Search...',
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      hintText: hintText,
      prefixIcon: const Icon(
        Icons.search,
        size: 20,
        color: AppColors.onSurfaceVariant,
      ),
      showClearButton: true,
      onClear: onClear,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? counterText;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Called when the clear button is pressed. When null and [showClearButton]
  /// is set, the controller is cleared and [onChanged] receives an empty string.
  final VoidCallback? onClear;

  /// Shows a clear button that appears only while the field has text.
  /// Requires a [controller].
  final bool showClearButton;

  Widget? _buildSuffix() {
    final c = controller;
    if (!showClearButton || c == null) return suffixIcon;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: c,
      builder: (context, value, _) {
        if (value.text.isEmpty) return suffixIcon ?? const SizedBox.shrink();
        return IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.clear, size: 18),
          onPressed: () {
            if (onClear != null) {
              onClear!();
            } else {
              c.clear();
              onChanged?.call('');
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          // The visible label is exposed through the field's semantics below.
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
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            minLines: minLines,
            maxLength: maxLength,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            enabled: enabled,
            autofocus: autofocus,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              errorText: errorText,
              helperText: helperText,
              counterText: counterText,
              prefixIcon: prefixIcon,
              suffixIcon: _buildSuffix(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Specialized stateful template for password inputs with integrated visibility toggle.
class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String hintText;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  const AppPasswordField({
    super.key,
    this.controller,
    this.label = 'Password',
    this.hintText = 'Enter your account password',
    this.errorText,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hintText: widget.hintText,
      errorText: widget.errorText,
      obscureText: _obscureText,
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
      suffixIcon: IconButton(
        tooltip: _obscureText ? 'Show password' : 'Hide password',
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 20,
          color: AppColors.onSurfaceVariant,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
    );
  }
}
