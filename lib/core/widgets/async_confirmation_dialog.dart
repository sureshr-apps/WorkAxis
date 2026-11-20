import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';

typedef ConfirmationDialogBuilder = Widget Function(
  BuildContext context,
  Widget content,
  List<Widget> actions,
);

/// Shows a confirmation dialog that performs its request before closing.
///
/// Returning `false` or throwing keeps the dialog open so the user can read
/// the error and retry. The raw exception is never shown.
Future<bool> showAsyncConfirmationDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required String confirmLabel,
  required Future<bool> Function() onConfirm,
  String? Function()? failureMessage,
  bool destructive = false,
  ConfirmationDialogBuilder? dialogBuilder,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AsyncConfirmationDialog(
      title: title,
      content: content,
      confirmLabel: confirmLabel,
      onConfirm: onConfirm,
      failureMessage: failureMessage,
      destructive: destructive,
      dialogBuilder: dialogBuilder,
    ),
  );
  return result ?? false;
}

class _AsyncConfirmationDialog extends StatefulWidget {
  const _AsyncConfirmationDialog({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.onConfirm,
    required this.failureMessage,
    required this.destructive,
    required this.dialogBuilder,
  });

  final String title;
  final Widget content;
  final String confirmLabel;
  final Future<bool> Function() onConfirm;
  final String? Function()? failureMessage;
  final bool destructive;
  final ConfirmationDialogBuilder? dialogBuilder;

  @override
  State<_AsyncConfirmationDialog> createState() =>
      _AsyncConfirmationDialogState();
}

class _AsyncConfirmationDialogState extends State<_AsyncConfirmationDialog> {
  bool _isBusy = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    var succeeded = false;
    try {
      succeeded = await widget.onConfirm();
    } catch (_) {
      succeeded = false;
    }

    if (!mounted) return;
    if (succeeded) {
      Navigator.of(context).pop(true);
      return;
    }

    final suppliedMessage = widget.failureMessage?.call()?.trim();
    setState(() {
      _isBusy = false;
      _errorMessage = suppliedMessage == null || suppliedMessage.isEmpty
          ? 'The request could not be completed. Try again.'
          : suppliedMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.content,
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.statusUrgentContainer,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.statusUrgentText,
              ),
            ),
          ),
        ],
      ],
    );
    final actions = [
      AppButton.outlined(
        text: 'Cancel',
        isFullWidth: false,
        onPressed: _isBusy ? null : () => Navigator.of(context).pop(false),
      ),
      AppButton(
        text: widget.confirmLabel,
        variant: widget.destructive
            ? AppButtonVariant.destructive
            : AppButtonVariant.primary,
        isFullWidth: false,
        isLoading: _isBusy,
        onPressed: _isBusy ? null : _confirm,
      ),
    ];
    final child =
        widget.dialogBuilder?.call(context, content, actions) ??
        AlertDialog(
          title: Text(widget.title),
          content: content,
          actions: actions,
        );

    return PopScope(canPop: !_isBusy, child: child);
  }
}
