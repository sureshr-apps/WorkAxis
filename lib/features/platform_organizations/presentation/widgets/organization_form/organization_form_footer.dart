import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/app_button.dart';

/// Cancel / submit toolbar shared by the add and edit organization forms.
class OrganizationFormFooter extends StatelessWidget {
  const OrganizationFormFooter({
    super.key,
    required this.submitLabel,
    required this.submitIcon,
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
  });

  final String submitLabel;
  final IconData submitIcon;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < AppBreakpoints.formSplit;
        final cancel = AppButton.outlined(
          text: 'Cancel',
          isFullWidth: isNarrow,
          onPressed: isLoading ? null : onCancel,
        );
        final submit = AppButton.primary(
          text: submitLabel,
          iconData: submitIcon,
          isFullWidth: isNarrow,
          isLoading: isLoading,
          onPressed: onSubmit,
        );
        const note = _EncryptionNote();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.outlineSubtle),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    cancel,
                    const SizedBox(height: AppSpacing.sm),
                    submit,
                    const SizedBox(height: AppSpacing.sm),
                    note,
                  ],
                )
              : Row(
                  children: [
                    const Expanded(child: note),
                    const SizedBox(width: AppSpacing.md),
                    cancel,
                    const SizedBox(width: AppSpacing.md),
                    submit,
                  ],
                ),
        );
      },
    );
  }
}

class _EncryptionNote extends StatelessWidget {
  const _EncryptionNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 16, color: AppColors.statusActive),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'End-to-end tenant database encryption enabled',
            style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
