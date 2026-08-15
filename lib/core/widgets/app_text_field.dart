import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefix,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLength,
    super.key,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurface,
          ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefix: prefix,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.defaultRadius),
            topRight: Radius.circular(AppRadius.defaultRadius),
          ),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.defaultRadius),
            topRight: Radius.circular(AppRadius.defaultRadius),
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.defaultRadius),
            topRight: Radius.circular(AppRadius.defaultRadius),
          ),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.defaultRadius),
            topRight: Radius.circular(AppRadius.defaultRadius),
          ),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.defaultRadius),
            topRight: Radius.circular(AppRadius.defaultRadius),
          ),
        ),
      ),
    );
  }
}
