import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

Future<bool> showLeaveReviewDialog({
  required BuildContext context,
  required LeaveRequest request,
  required LeaveStatus decision,
  required Future<bool> Function(String? notes) onSubmit,
  String? Function()? failureMessage,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LeaveReviewDialog(
        request: request,
        decision: decision,
        onSubmit: onSubmit,
        failureMessage: failureMessage,
      ),
    ) ??
    false;

class _LeaveReviewDialog extends StatefulWidget {
  const _LeaveReviewDialog({
    required this.request,
    required this.decision,
    required this.onSubmit,
    required this.failureMessage,
  });

  final LeaveRequest request;
  final LeaveStatus decision;
  final Future<bool> Function(String? notes) onSubmit;
  final String? Function()? failureMessage;

  @override
  State<_LeaveReviewDialog> createState() => _LeaveReviewDialogState();
}

class _LeaveReviewDialogState extends State<_LeaveReviewDialog> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final notes = _notesController.text.trim();
    var saved = false;
    try {
      saved = await widget.onSubmit(notes.isEmpty ? null : notes);
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }

    final suppliedMessage = widget.failureMessage?.call()?.trim();
    setState(() {
      _isSubmitting = false;
      _errorMessage = suppliedMessage == null || suppliedMessage.isEmpty
          ? 'The leave request could not be reviewed. Try again.'
          : suppliedMessage;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isSubmitting,
    child: AlertDialog(
      title: Text(
        widget.request.applicantRole == UserRole.branchManager
            ? 'Review manager leave'
            : 'Review leave request',
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.request.applicantName} · '
              '${widget.request.leaveType.label}',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _notesController,
              label: 'Review note (optional)',
              hintText: 'Add a note for the applicant',
              maxLines: 3,
              maxLength: 2000,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusUrgentText,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton.outlined(
          text: 'Cancel',
          isFullWidth: false,
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
        ),
        if (widget.decision == LeaveStatus.approved)
          AppButton.primary(
            text: 'Confirm approval',
            isFullWidth: false,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          )
        else
          AppButton.outlined(
            text: 'Confirm rejection',
            isFullWidth: false,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
      ],
    ),
  );
}
