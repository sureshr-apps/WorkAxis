import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

class LeaveReviewDecision {
  const LeaveReviewDecision({required this.status, required this.notes});

  final LeaveStatus status;
  final String? notes;
}

Future<LeaveReviewDecision?> showLeaveReviewDialog({
  required BuildContext context,
  required LeaveRequest request,
  required LeaveStatus decision,
}) => showDialog<LeaveReviewDecision>(
  context: context,
  builder: (context) =>
      _LeaveReviewDialog(request: request, decision: decision),
);

class _LeaveReviewDialog extends StatefulWidget {
  const _LeaveReviewDialog({required this.request, required this.decision});

  final LeaveRequest request;
  final LeaveStatus decision;

  @override
  State<_LeaveReviewDialog> createState() => _LeaveReviewDialogState();
}

class _LeaveReviewDialogState extends State<_LeaveReviewDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _finish(LeaveStatus status) => Navigator.of(context).pop(
    LeaveReviewDecision(
      status: status,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    ),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
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
            '${widget.request.applicantName} · ${widget.request.leaveType.label}',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _notesController,
            label: 'Review note (optional)',
            hintText: 'Add a note for the applicant',
            maxLines: 3,
            maxLength: 2000,
          ),
        ],
      ),
    ),
    actions: [
      AppButton.outlined(
        text: 'Cancel',
        isFullWidth: false,
        onPressed: () => Navigator.of(context).pop(),
      ),
      if (widget.decision == LeaveStatus.approved)
        AppButton.primary(
          text: 'Confirm approval',
          isFullWidth: false,
          onPressed: () => _finish(widget.decision),
        )
      else
        AppButton.outlined(
          text: 'Confirm rejection',
          isFullWidth: false,
          onPressed: () => _finish(widget.decision),
        ),
    ],
  );
}
