import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/license_form_fields.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_dialog_frame.dart';

/// Shared shell of the license action dialogs: title, form body, an inline
/// failure message and Cancel/submit actions. While saving, the dialog cannot
/// be dismissed and its submit button shows progress.
class LicenseDialogFrame extends StatelessWidget {
  const LicenseDialogFrame({
    super.key,
    required this.title,
    required this.body,
    required this.submitLabel,
    required this.isSaving,
    required this.onSubmit,
    this.submitEnabled = true,
    this.submitError,
  });

  final String title;
  final Widget body;
  final String submitLabel;
  final bool isSaving;
  final VoidCallback onSubmit;
  final bool submitEnabled;

  /// Failure from the last save attempt. The form values stay as entered.
  final String? submitError;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !isSaving,
    child: PlatformDialogFrame(
      title: title,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          if (submitError != null) ...[
            const SizedBox(height: AppSpacing.md),
            LicenseFormError(message: submitError!),
          ],
        ],
      ),
      actions: [
        AppButton.outlined(
          text: 'Cancel',
          isFullWidth: false,
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          text: submitLabel,
          isFullWidth: false,
          isLoading: isSaving,
          onPressed: isSaving || !submitEnabled ? null : onSubmit,
        ),
      ],
    ),
  );
}
