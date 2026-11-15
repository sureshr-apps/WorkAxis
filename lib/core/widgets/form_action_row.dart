import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/app_button.dart';

/// The Cancel and submit pair at the foot of every add and edit form.
///
/// Cancel is always on the left and the submit action on the right, in one
/// row. In a narrow row the submit action takes two thirds of the width so its
/// label fits; in a wide row both keep their natural width, aligned to the end.
class FormActionRow extends StatelessWidget {
  const FormActionRow({
    super.key,
    required this.submitLabel,
    required this.onCancel,
    this.onSubmit,
    this.submitIcon,
    this.isBusy = false,
  });

  final String submitLabel;
  final IconData? submitIcon;

  /// Null leaves the submit action disabled.
  final VoidCallback? onSubmit;
  final VoidCallback onCancel;

  /// Disables Cancel and shows progress on the submit action.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sharesRow =
            constraints.maxWidth < AppBreakpoints.formActionsShareWidth;
        final cancel = AppButton.outlined(
          text: 'Cancel',
          isFullWidth: sharesRow,
          onPressed: isBusy ? null : onCancel,
        );
        final submit = AppButton.primary(
          text: submitLabel,
          iconData: submitIcon,
          isFullWidth: sharesRow,
          isLoading: isBusy,
          onPressed: onSubmit,
        );
        if (sharesRow) {
          return Row(
            children: [
              Expanded(child: cancel),
              const SizedBox(width: AppSpacing.sm),
              Expanded(flex: 2, child: submit),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            cancel,
            const SizedBox(width: AppSpacing.sm),
            submit,
          ],
        );
      },
    );
  }
}
