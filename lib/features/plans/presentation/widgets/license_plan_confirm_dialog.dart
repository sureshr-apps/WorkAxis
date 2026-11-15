import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';

/// Opens a confirmation dialog for a plan action. Resolves to true when the
/// action succeeded and to false when the user cancelled.
Future<bool> showLicensePlanConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<bool> Function() onConfirm,
  String? Function()? failureMessage,
  bool destructive = true,
  IconData icon = Icons.warning_amber_rounded,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => LicensePlanConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      onConfirm: onConfirm,
      failureMessage: failureMessage,
      destructive: destructive,
      icon: icon,
    ),
  );
  return confirmed ?? false;
}

/// Confirmation dialog for a license plan action.
///
/// [onConfirm] performs the action and returns whether it succeeded. On
/// failure the dialog stays open and shows [failureMessage] (the server's
/// message when there is one).
class LicensePlanConfirmDialog extends StatefulWidget {
  const LicensePlanConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.failureMessage,
    this.destructive = true,
    this.icon = Icons.warning_amber_rounded,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final Future<bool> Function() onConfirm;
  final String? Function()? failureMessage;
  final bool destructive;
  final IconData icon;

  @override
  State<LicensePlanConfirmDialog> createState() =>
      _LicensePlanConfirmDialogState();
}

class _LicensePlanConfirmDialogState extends State<LicensePlanConfirmDialog> {
  bool _isBusy = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    final succeeded = await widget.onConfirm();
    if (!mounted) return;
    if (succeeded) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isBusy = false;
      _errorMessage =
          widget.failureMessage?.call() ??
          'The change could not be saved. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.destructive
        ? AppColors.statusUrgent
        : AppColors.primary;
    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.isCompact ? AppSpacing.md : AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: accent, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(widget.title, style: AppTypography.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(widget.message, style: AppTypography.bodyMedium),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                _FailureNotice(message: _errorMessage!),
              ],
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton.outlined(
                    text: 'Cancel',
                    isFullWidth: false,
                    onPressed: _isBusy
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  AppButton(
                    text: widget.confirmLabel,
                    variant: widget.destructive
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.primary,
                    isFullWidth: false,
                    isLoading: _isBusy,
                    onPressed: _confirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailureNotice extends StatelessWidget {
  const _FailureNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.statusUrgentContainer,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(color: AppColors.statusUrgentBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              size: 18,
              color: AppColors.statusUrgent,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.statusUrgentText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
