import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_date_picker_field.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employees/domain/models/employee_workforce_history.dart';
import 'package:workaxis/features/employees/domain/repositories/employee_workforce_repository.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

class EmployeeWorkforceTabs extends StatefulWidget {
  const EmployeeWorkforceTabs({
    super.key,
    required this.memberId,
    required this.access,
    required this.canEdit,
    required this.overview,
    this.activeBranchId,
  });

  final String memberId;
  final UserAccessContext access;
  final bool canEdit;
  final Widget overview;
  final String? activeBranchId;

  @override
  State<EmployeeWorkforceTabs> createState() => _EmployeeWorkforceTabsState();
}

class _EmployeeWorkforceTabsState extends State<EmployeeWorkforceTabs> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  EmployeeWorkforceHistory? _history;

  EmployeeWorkforceRepository get _repository =>
      context.read<EmployeeWorkforceRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EmployeeWorkforceTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberId != widget.memberId ||
        oldWidget.activeBranchId != widget.activeBranchId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.getHistory(
        access: widget.access,
        memberId: widget.memberId,
        activeBranchId: widget.activeBranchId,
      );
      if (!mounted) return;
      setState(() => _history = result);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = userMessageFor(
          error,
          null,
          fallback: 'Employee schedule and salary history could not be loaded.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Overview'),
              icon: Icon(Icons.person_outline),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Schedule & Shifts'),
              icon: Icon(Icons.schedule_outlined),
            ),
            ButtonSegment(
              value: 2,
              label: Text('Salary'),
              icon: Icon(Icons.payments_outlined),
            ),
          ],
          selected: {_tab},
          onSelectionChanged: (selection) =>
              setState(() => _tab = selection.first),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_tab == 0)
          widget.overview
        else if (_loading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          DashboardSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!, style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                AppButton.outlined(
                  text: 'Retry',
                  iconData: Icons.refresh,
                  isFullWidth: false,
                  onPressed: _load,
                ),
              ],
            ),
          )
        else if (_tab == 1)
          _schedulePanel(_history?.schedules ?? const [])
        else
          _salaryPanel(_history?.compensations ?? const []),
      ],
    );
  }

  Widget _schedulePanel(List<ScheduleVersion> history) => DashboardSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(
          title: 'Schedule & shifts',
          subtitle:
              'Weekly day off and shift hours, with effective-date history.',
          action: widget.canEdit
              ? AppButton.outlined(
                  text: 'Add schedule',
                  iconData: Icons.add,
                  isFullWidth: false,
                  onPressed: _editSchedule,
                )
              : null,
        ),
        if (history.isEmpty)
          const _EmptyHistory(message: 'No schedule history is available yet.')
        else
          for (final schedule in history) ...[
            const Divider(height: AppSpacing.lg),
            _HistoryRow(
              title: schedule.shiftHours,
              subtitle:
                  '${_hours(schedule.dailyWorkHours)} · ${_weekdayNames[schedule.weeklyDayOff]} off',
              dateLabel: _effectiveLabel(
                schedule.effectiveFrom,
                schedule.effectiveTo,
              ),
            ),
          ],
      ],
    ),
  );

  Widget _salaryPanel(
    List<CompensationVersion> history,
  ) => DashboardSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(
          title: 'Salary history',
          subtitle: 'Monthly salary rates and the date each rate takes effect.',
          action: widget.canEdit
              ? AppButton.outlined(
                  text: 'Add salary rate',
                  iconData: Icons.add,
                  isFullWidth: false,
                  onPressed: _editSalary,
                )
              : null,
        ),
        if (history.isEmpty)
          const _EmptyHistory(message: 'No salary history is available yet.')
        else
          for (final salary in history) ...[
            const Divider(height: AppSpacing.lg),
            _HistoryRow(
              title: _money(salary.monthlySalary),
              subtitle: 'Monthly salary',
              dateLabel: _effectiveLabel(
                salary.effectiveFrom,
                salary.effectiveTo,
              ),
            ),
          ],
      ],
    ),
  );

  Future<void> _editSchedule() async {
    final dailyHours = TextEditingController(text: '8');
    final shift = TextEditingController(text: '09:00 AM - 05:00 PM');
    var effectiveFrom = _businessToday();
    var weekdayOff = DateTime.sunday % 7;
    var saving = false;
    String? validation;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add schedule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppDatePickerField(
                  label: 'Effective from',
                  valueText: DateFormat('dd MMM yyyy').format(effectiveFrom),
                  prefixIcon: const Icon(Icons.event_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: effectiveFrom,
                      firstDate: _businessToday(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => effectiveFrom = picked);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: dailyHours,
                  label: 'Daily work hours',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: shift,
                  label: 'Shift time',
                  hintText: '09:00 AM - 05:00 PM',
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<int>(
                  initialValue: weekdayOff,
                  decoration: const InputDecoration(
                    labelText: 'Weekly day off',
                  ),
                  items: [
                    for (var day = 0; day < _weekdayNames.length; day++)
                      DropdownMenuItem(
                        value: day,
                        child: Text(_weekdayNames[day]),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => weekdayOff = value);
                  },
                ),
                if (validation != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    validation!,
                    style: const TextStyle(color: AppColors.statusUrgentText),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final hours = double.tryParse(dailyHours.text.trim());
                      if (hours == null || hours < .5 || hours > 24) {
                        setDialogState(
                          () => validation =
                              'Enter work hours between 0.5 and 24.',
                        );
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        validation = null;
                      });
                      try {
                        await _repository.saveSchedule(
                          access: widget.access,
                          memberId: widget.memberId,
                          effectiveFrom: _dateKey(effectiveFrom),
                          dailyWorkHours: hours,
                          shiftHours: shift.text.trim(),
                          weeklyDayOff: weekdayOff,
                          activeBranchId: widget.activeBranchId,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        setDialogState(() {
                          saving = false;
                          validation = userMessageFor(
                            error,
                            null,
                            fallback: 'The schedule could not be saved.',
                          );
                        });
                      }
                    },
              child: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save schedule'),
            ),
          ],
        ),
      ),
    );
    dailyHours.dispose();
    shift.dispose();
    if (saved == true) _load();
  }

  Future<void> _editSalary() async {
    final salary = TextEditingController();
    var effectiveFrom = _businessToday();
    var saving = false;
    String? validation;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add salary rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDatePickerField(
                label: 'Effective from',
                valueText: DateFormat('dd MMM yyyy').format(effectiveFrom),
                prefixIcon: const Icon(Icons.event_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: effectiveFrom,
                    firstDate: _businessToday(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => effectiveFrom = picked);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: salary,
                label: 'Monthly salary',
                prefixText: '₹',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              if (validation != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  validation!,
                  style: const TextStyle(color: AppColors.statusUrgentText),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(salary.text.trim());
                      if (amount == null || amount < 0) {
                        setDialogState(
                          () => validation = 'Enter a valid monthly salary.',
                        );
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        validation = null;
                      });
                      try {
                        await _repository.saveCompensation(
                          access: widget.access,
                          memberId: widget.memberId,
                          effectiveFrom: _dateKey(effectiveFrom),
                          monthlySalary: amount,
                          activeBranchId: widget.activeBranchId,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        setDialogState(() {
                          saving = false;
                          validation = userMessageFor(
                            error,
                            null,
                            fallback: 'The salary rate could not be saved.',
                          );
                        });
                      }
                    },
              child: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save salary'),
            ),
          ],
        ),
      ),
    );
    salary.dispose();
    if (saved == true) _load();
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.sm,
    children: [
      SizedBox(
        width: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      ?action,
    ],
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
  });
  final String title;
  final String subtitle;
  final String dateLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(
        dateLabel,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        textAlign: TextAlign.end,
      ),
    ],
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Text(
      message,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );
}

const _weekdayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];
DateTime _businessToday() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime(now.year, now.month, now.day);
}

String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
String _hours(double value) =>
    '${value == value.roundToDouble() ? value.toInt() : value.toStringAsFixed(1)} hours/day';
String _money(double value) => NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
).format(value);
String _effectiveLabel(DateTime start, DateTime? end) =>
    'From ${DateFormat('dd MMM yyyy').format(start)}${end == null ? ' · Current' : ' to ${DateFormat('dd MMM yyyy').format(end.subtract(const Duration(days: 1)))}'}';
