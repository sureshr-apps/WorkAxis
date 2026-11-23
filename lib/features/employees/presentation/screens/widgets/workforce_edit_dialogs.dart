import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/widgets/app_date_picker_field.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';

/// Weekday names indexed like `weeklyDayOff` (0 = Sunday).
const workforceWeekdayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

/// A new schedule version entered in [ScheduleEditDialog].
typedef ScheduleDraft = ({
  String effectiveFrom,
  double dailyWorkHours,
  String shiftHours,
  int weeklyDayOff,
});

/// A new salary version entered in [SalaryEditDialog].
typedef SalaryDraft = ({String effectiveFrom, double monthlySalary});

/// Adds a schedule version. Pops `true` once [onSave] succeeds.
///
/// The dialog owns its text controllers, so they live exactly as long as the
/// dialog route (including its exit animation), and it cannot be dismissed
/// while a save is in flight.
class ScheduleEditDialog extends StatefulWidget {
  const ScheduleEditDialog({
    super.key,
    required this.businessToday,
    required this.onSave,
  });

  final DateTime businessToday;
  final Future<void> Function(ScheduleDraft draft) onSave;

  @override
  State<ScheduleEditDialog> createState() => _ScheduleEditDialogState();
}

class _ScheduleEditDialogState extends State<ScheduleEditDialog> {
  final _dailyHours = TextEditingController(text: '8');
  final _shift = TextEditingController(text: '09:00 AM - 05:00 PM');
  late DateTime _effectiveFrom = widget.businessToday;
  int _weekdayOff = DateTime.sunday % 7;
  bool _saving = false;
  String? _validation;

  @override
  void dispose() {
    _dailyHours.dispose();
    _shift.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final hours = double.tryParse(_dailyHours.text.trim());
    if (hours == null || hours < .5 || hours > 24) {
      setState(() => _validation = 'Enter work hours between 0.5 and 24.');
      return;
    }
    setState(() {
      _saving = true;
      _validation = null;
    });
    try {
      await widget.onSave((
        effectiveFrom: BusinessTime.keyOfDate(_effectiveFrom),
        dailyWorkHours: hours,
        shiftHours: _shift.text.trim(),
        weeklyDayOff: _weekdayOff,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _validation = userMessageFor(
          error,
          stackTrace,
          fallback: 'The schedule could not be saved.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Add schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EffectiveFromField(
              value: _effectiveFrom,
              firstDate: widget.businessToday,
              onChanged: (picked) => setState(() => _effectiveFrom = picked),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _dailyHours,
              label: 'Daily work hours',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _shift,
              label: 'Shift time',
              hintText: '09:00 AM - 05:00 PM',
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              initialValue: _weekdayOff,
              decoration: const InputDecoration(labelText: 'Weekly day off'),
              items: [
                for (var day = 0; day < workforceWeekdayNames.length; day++)
                  DropdownMenuItem(
                    value: day,
                    child: Text(workforceWeekdayNames[day]),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _weekdayOff = value);
              },
            ),
            if (_validation != null) _ValidationText(_validation!),
          ],
        ),
      ),
      actions: _dialogActions(
        context,
        saving: _saving,
        saveLabel: 'Save schedule',
        onSave: _save,
      ),
    ),
  );
}

/// Adds a salary version. Pops `true` once [onSave] succeeds.
class SalaryEditDialog extends StatefulWidget {
  const SalaryEditDialog({
    super.key,
    required this.businessToday,
    required this.onSave,
  });

  final DateTime businessToday;
  final Future<void> Function(SalaryDraft draft) onSave;

  @override
  State<SalaryEditDialog> createState() => _SalaryEditDialogState();
}

class _SalaryEditDialogState extends State<SalaryEditDialog> {
  final _salary = TextEditingController();
  late DateTime _effectiveFrom = widget.businessToday;
  bool _saving = false;
  String? _validation;

  @override
  void dispose() {
    _salary.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_salary.text.trim());
    if (amount == null || amount < 0) {
      setState(() => _validation = 'Enter a valid monthly salary.');
      return;
    }
    setState(() {
      _saving = true;
      _validation = null;
    });
    try {
      await widget.onSave((
        effectiveFrom: BusinessTime.keyOfDate(_effectiveFrom),
        monthlySalary: amount,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _validation = userMessageFor(
          error,
          stackTrace,
          fallback: 'The salary rate could not be saved.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Add salary rate'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EffectiveFromField(
            value: _effectiveFrom,
            firstDate: widget.businessToday,
            onChanged: (picked) => setState(() => _effectiveFrom = picked),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _salary,
            label: 'Monthly salary',
            prefixText: '₹',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (_validation != null) _ValidationText(_validation!),
        ],
      ),
      actions: _dialogActions(
        context,
        saving: _saving,
        saveLabel: 'Save salary',
        onSave: _save,
      ),
    ),
  );
}

class _EffectiveFromField extends StatelessWidget {
  const _EffectiveFromField({
    required this.value,
    required this.firstDate,
    required this.onChanged,
  });

  final DateTime value;
  final DateTime firstDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => AppDatePickerField(
    label: 'Effective from',
    valueText: DateFormat('dd MMM yyyy').format(value),
    prefixIcon: const Icon(Icons.event_outlined),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: firstDate,
        lastDate: DateTime(2100),
      );
      if (picked != null) onChanged(picked);
    },
  );
}

class _ValidationText extends StatelessWidget {
  const _ValidationText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Text(
      message,
      style: const TextStyle(color: AppColors.statusUrgentText),
    ),
  );
}

List<Widget> _dialogActions(
  BuildContext context, {
  required bool saving,
  required String saveLabel,
  required VoidCallback onSave,
}) => [
  TextButton(
    onPressed: saving ? null : () => Navigator.pop(context, false),
    child: const Text('Cancel'),
  ),
  FilledButton(
    onPressed: saving ? null : onSave,
    child: saving
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(saveLabel),
  ),
];
