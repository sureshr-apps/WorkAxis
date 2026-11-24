import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/employee_home/domain/validators/checkout_correction_validator.dart';
import 'package:workaxis/features/employee_home/presentation/formatting/business_time_text.dart';
import 'package:workaxis/features/employee_home/presentation/models/correctable_checkout_text.dart';

/// Submits a correction; returns whether it was sent.
typedef CheckoutCorrectionSubmit = Future<bool> Function(
  DateTime checkOutAt,
  String reason,
);

/// Opens the correction dialog for [entry]. Resolves to true once sent.
Future<bool?> showCheckoutCorrectionDialog({
  required BuildContext context,
  required AttendanceEntry entry,
  required CheckoutCorrectionSubmit onSubmit,
  required String? Function() failureMessage,
  Now now = systemNow,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => CheckoutCorrectionDialog(
    entry: entry,
    onSubmit: onSubmit,
    failureMessage: failureMessage,
    now: now,
  ),
);

/// Asks for the actual check-out time (business timezone) and a reason.
class CheckoutCorrectionDialog extends StatefulWidget {
  const CheckoutCorrectionDialog({
    super.key,
    required this.entry,
    required this.onSubmit,
    required this.failureMessage,
    this.now = systemNow,
  });

  final AttendanceEntry entry;
  final CheckoutCorrectionSubmit onSubmit;
  final String? Function() failureMessage;
  final Now now;

  @override
  State<CheckoutCorrectionDialog> createState() =>
      _CheckoutCorrectionDialogState();
}

class _CheckoutCorrectionDialogState extends State<CheckoutCorrectionDialog> {
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _checkOutAt;
  String? _checkOutError;
  String? _reasonError;
  String? _formError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default to the scheduled shift end, the most likely real check-out.
    _checkOutAt = widget.entry.scheduledEndAt;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickCheckOut() async {
    final entry = widget.entry;
    final checkIn = entry.checkInAt ?? widget.now();
    final latest = _earlier(
      widget.now(),
      checkIn.add(CheckoutCorrectionValidator.maxSessionLength),
    );
    final first = _dateOnly(BusinessTimeText.wallClock(checkIn));
    final last = _dateOnly(BusinessTimeText.wallClock(latest));
    final initial = BusinessTimeText.wallClock(_checkOutAt ?? latest);
    final initialDate = _clampDate(_dateOnly(initial), first, last);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: first,
      lastDate: last.isBefore(first) ? first : last,
      helpText: 'Check-out date',
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      helpText: 'Check-out time (IST)',
    );
    if (!mounted || time == null) return;
    setState(() {
      _checkOutAt = BusinessTimeText.instantAt(date, time);
      _checkOutError = null;
      _formError = null;
    });
  }

  bool _validate() {
    setState(() {
      _checkOutError = CheckoutCorrectionValidator.checkOutError(
        entry: widget.entry,
        checkOutAt: _checkOutAt,
        now: widget.now(),
        formatTime: BusinessTimeText.shortDateTime,
      );
      _reasonError = CheckoutCorrectionValidator.reasonError(
        _reasonController.text,
      );
      _formError = null;
    });
    return _checkOutError == null && _reasonError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final checkOutAt = _checkOutAt!;
    setState(() => _isSaving = true);
    final sent = await widget.onSubmit(
      checkOutAt,
      _reasonController.text.trim(),
    );
    if (!mounted) return;
    if (sent) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSaving = false;
      _formError =
          widget.failureMessage() ??
          'The correction request could not be sent. Try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final checkOut = _checkOutAt;
    return AlertDialog(
      title: const Text('Request check-out correction'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${entry.shiftDateLabel} • ${entry.checkInLabel}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                entry.checkoutProblemLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusUrgentText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Tell your manager when you actually checked out. The time '
                'is used only if your manager approves it.',
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                key: const Key('checkout-correction-time'),
                onPressed: _isSaving ? null : _pickCheckOut,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(
                  checkOut == null
                      ? 'Choose actual check-out (IST)'
                      : 'Actual check-out: '
                            '${BusinessTimeText.shortDateTime(checkOut)} IST',
                ),
              ),
              if (_checkOutError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _checkOutError!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _reasonController,
                label: 'Reason',
                hintText: 'e.g. Forgot to check out when leaving the branch',
                minLines: 3,
                maxLines: 5,
                maxLength: CheckoutCorrectionValidator.maxReasonLength,
                errorText: _reasonError,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_reasonError != null) setState(() => _reasonError = null);
                },
              ),
              if (_formError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _formError!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppButton.outlined(
          text: 'Cancel',
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          isFullWidth: false,
        ),
        AppButton.primary(
          text: 'Send request',
          iconData: Icons.send_outlined,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _submit,
          isFullWidth: false,
        ),
      ],
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  static DateTime _clampDate(DateTime value, DateTime first, DateTime last) {
    if (value.isBefore(first)) return first;
    if (value.isAfter(last)) return last.isBefore(first) ? first : last;
    return value;
  }
}
