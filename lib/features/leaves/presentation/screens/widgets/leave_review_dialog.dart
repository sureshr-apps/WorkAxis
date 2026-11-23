import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/presentation/controllers/leave_preview_controller.dart';
import 'package:workaxis/features/leaves/presentation/screens/widgets/leave_preview_summary.dart';

Future<bool> showLeaveReviewDialog({
  required BuildContext context,
  required LeaveRequest request,
  required LeaveStatus decision,
  required LeavePreviewController preview,
  required Future<bool> Function(String? notes) onSubmit,
  String? Function()? failureMessage,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LeaveReviewDialog(
        request: request,
        decision: decision,
        preview: preview,
        onSubmit: onSubmit,
        failureMessage: failureMessage,
      ),
    ) ??
    false;

class LeaveReviewDialog extends StatefulWidget {
  const LeaveReviewDialog({
    super.key,
    required this.request,
    required this.decision,
    required this.preview,
    required this.onSubmit,
    required this.failureMessage,
  });

  final LeaveRequest request;
  final LeaveStatus decision;

  /// Paid/unpaid preview of [request]; owned and disposed by the caller.
  final LeavePreviewController preview;
  final Future<bool> Function(String? notes) onSubmit;
  final String? Function()? failureMessage;

  @override
  State<LeaveReviewDialog> createState() => _LeaveReviewDialogState();
}

class _LeaveReviewDialogState extends State<LeaveReviewDialog> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.preview.previewReview(widget.request);
  }

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

  String _dateRange(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final start = localizations.formatMediumDate(widget.request.startDate);
    final end = localizations.formatMediumDate(widget.request.endDate);
    return start == end ? start : '$start – $end';
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.request.applicantName} · '
                '${widget.request.leaveTypeName}',
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _dateRange(context),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              LeavePreviewSummary(
                controller: widget.preview,
                typeName: widget.request.leaveTypeName,
                paid: widget.request.leaveTypePaid,
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
