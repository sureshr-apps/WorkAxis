import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/form_action_row.dart';

/// Cancel / submit toolbar shared by the add and edit organization forms.
///
/// The actions stay on one row at every width; the encryption note sits to
/// their left on wide layouts and beneath them on narrow ones.
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
  final FutureOr<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < AppBreakpoints.formSplit;
        final actions = FormActionRow(
          submitLabel: submitLabel,
          submitIcon: submitIcon,
          isBusy: isLoading,
          onCancel: onCancel,
          onSubmit: onSubmit,
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
                    actions,
                    const SizedBox(height: AppSpacing.sm),
                    note,
                  ],
                )
              : Row(
                  children: [
                    const Expanded(child: note),
                    const SizedBox(width: AppSpacing.md),
                    actions,
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
