import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/async_confirmation_dialog.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/checkout_correction.dart';
import 'package:workaxis/features/attendance/presentation/attendance_time_format.dart';
import 'package:workaxis/features/attendance/presentation/overtime_hours_input.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_dialogs.dart';

/// Confirms a check-out correction decision with an optional note. The
/// request runs inside the dialog; a failure keeps it open with the reason.
Future<bool> confirmCorrectionDecision(
  BuildContext context, {
  required CheckoutCorrection correction,
  required CorrectionDecision decision,
  required Future<bool> Function(String note) onConfirm,
  String? Function()? failureMessage,
}) {
  final approve = decision == CorrectionDecision.approve;
  final title = approve ? 'Approve correction?' : 'Reject correction?';
  final requested = AttendanceTimeFormat.timeOnShift(
    correction.requestedCheckOutAt,
    correction.workDate,
  );
  final shift = AppFormatters.formatDate(correction.workDate);
  var note = '';
  return showAsyncConfirmationDialog(
    context: context,
    title: title,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          approve
              ? 'The check-out for ${correction.employeeName} on the $shift '
                    'shift will be set to $requested.'
              : 'The check-out for ${correction.employeeName} on the $shift '
                    'shift stays as recorded. They can submit a new request.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        _StatefulTextField(
          label: 'Note (optional)',
          hintText: 'Visible to the employee',
          maxLines: 3,
          maxLength: 500,
          onChanged: (value) => note = value,
        ),
      ],
    ),
    confirmLabel: approve ? 'Approve' : 'Reject',
    destructive: !approve,
    onConfirm: () => onConfirm(note),
    failureMessage: failureMessage,
    dialogBuilder: (context, content, actions) => AttendanceDialogShell(
      title: title,
      actions: actions,
      children: [content],
    ),
  );
}

/// Confirms approving overtime (hours editable, at most the potential) or
/// rejecting it. [onConfirm] receives the approved hours, null on reject.
Future<bool> confirmOvertimeDecision(
  BuildContext context, {
  required AttendanceEntry entry,
  required OvertimeDecision decision,
  required Future<bool> Function(double? approvedHours) onConfirm,
  String? Function()? failureMessage,
}) {
  final approve = decision == OvertimeDecision.approve;
  final potential = entry.potentialOvertimeHours;
  final title = approve ? 'Approve overtime?' : 'Reject overtime?';
  final shift = AppFormatters.formatDate(entry.workDate);
  var hoursText = OvertimeHoursInput.initialText(potential);
  String? validationError;
  return showAsyncConfirmationDialog(
    context: context,
    title: title,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          approve
              ? '${entry.employeeName} has '
                    '${AttendanceTimeFormat.hours(potential)} of potential '
                    'overtime on the $shift shift. Only approved hours are paid.'
              : 'No overtime will be paid for ${entry.employeeName} on the '
                    '$shift shift. Attendance status is not changed.',
          style: AppTypography.bodyMedium,
        ),
        if (approve) ...[
          const SizedBox(height: AppSpacing.md),
          _StatefulTextField(
            label: 'Hours to approve',
            initialText: hoursText,
            helperText:
                'Up to ${AttendanceTimeFormat.hours(potential)}, 2 decimals',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: (value) => OvertimeHoursInput.validate(value, potential),
            onChanged: (value) => hoursText = value,
          ),
        ],
      ],
    ),
    confirmLabel: approve ? 'Approve' : 'Reject',
    destructive: !approve,
    onConfirm: () async {
      if (!approve) return onConfirm(null);
      validationError = OvertimeHoursInput.validate(hoursText, potential);
      if (validationError != null) return false;
      return onConfirm(OvertimeHoursInput.parse(hoursText, potential));
    },
    failureMessage: () => validationError ?? failureMessage?.call(),
    dialogBuilder: (context, content, actions) => AttendanceDialogShell(
      title: title,
      actions: actions,
      children: [content],
    ),
  );
}

/// Owns its controller so it outlives the dialog's closing animation.
class _StatefulTextField extends StatefulWidget {
  const _StatefulTextField({
    required this.label,
    required this.onChanged,
    this.initialText = '',
    this.hintText,
    this.helperText,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final String initialText;
  final String? hintText;
  final String? helperText;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String value)? validator;

  @override
  State<_StatefulTextField> createState() => _StatefulTextFieldState();
}

class _StatefulTextFieldState extends State<_StatefulTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: _controller,
    label: widget.label,
    hintText: widget.hintText,
    helperText: widget.helperText,
    errorText: _error,
    maxLines: widget.maxLines,
    maxLength: widget.maxLength,
    keyboardType: widget.keyboardType,
    inputFormatters: widget.inputFormatters,
    onChanged: (value) {
      widget.onChanged(value);
      final validator = widget.validator;
      if (validator != null) setState(() => _error = validator(value));
    },
  );
}
