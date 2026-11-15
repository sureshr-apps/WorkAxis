import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_date_picker_field.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/employees/domain/models/member_field.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/member_form_feedback.dart';

/// Reusable work hours and shift timing configuration section.
///
/// Features bidirectional synchronization:
/// - Adjusting work hours automatically recalculates and shifts the End Time,
///   preserving Start Time (defaults to 9:00 AM).
/// - Adjusting the Shift Start or Shift End time automatically
///   recalculates the daily work hours.
/// - Keeps [shiftHoursController] populated in the background with the formatted
///   window range (e.g., '09:00 AM - 05:00 PM') for database storage.
class WorkHoursShiftSection extends StatefulWidget {
  const WorkHoursShiftSection({
    super.key,
    required this.workHoursController,
    required this.shiftHoursController,
    this.initialWorkHours = 8.0,
    this.initialShiftHours = '09:00 AM - 05:00 PM',
    this.feedback = MemberFormFeedback.none,
  });

  final TextEditingController workHoursController;
  final TextEditingController shiftHoursController;
  final double initialWorkHours;
  final String? initialShiftHours;
  final MemberFormFeedback feedback;

  @override
  State<WorkHoursShiftSection> createState() => _WorkHoursShiftSectionState();
}

class _WorkHoursShiftSectionState extends State<WorkHoursShiftSection> {
  static const List<double> _presetHours = [4.0, 6.0, 8.0, 9.0, 10.0];

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initTimesAndControllers();
    widget.workHoursController.addListener(_onWorkHoursChanged);
    widget.shiftHoursController.addListener(_onShiftHoursChanged);
  }

  void _initTimesAndControllers() {
    final parsed = _parseShiftRange(widget.initialShiftHours);
    if (parsed != null) {
      _startTime = parsed.start;
      _endTime = parsed.end;
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      final totalMinutes =
          (_startTime.hour * 60 +
              _startTime.minute +
              (widget.initialWorkHours * 60).round()) %
          1440;
      _endTime = TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
    }

    _isSyncing = true;
    if (widget.workHoursController.text.trim().isEmpty) {
      widget.workHoursController.text = _formatHours(widget.initialWorkHours);
    }
    if (widget.shiftHoursController.text.trim().isEmpty) {
      widget.shiftHoursController.text =
          '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}';
    }
    _isSyncing = false;
  }

  @override
  void dispose() {
    widget.workHoursController.removeListener(_onWorkHoursChanged);
    widget.shiftHoursController.removeListener(_onShiftHoursChanged);
    super.dispose();
  }

  void _onWorkHoursChanged() {
    if (_isSyncing) return;
    final hours = double.tryParse(widget.workHoursController.text.trim());
    if (hours == null || hours <= 0 || hours > 24) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = (startMinutes + (hours * 60).round()) % 1440;
    final newEndTime = TimeOfDay(
      hour: endMinutes ~/ 60,
      minute: endMinutes % 60,
    );

    _isSyncing = true;
    setState(() {
      _endTime = newEndTime;
      widget.shiftHoursController.text =
          '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}';
    });
    _isSyncing = false;
  }

  void _onShiftHoursChanged() {
    if (_isSyncing) return;
    final parsed = _parseShiftRange(widget.shiftHoursController.text.trim());
    if (parsed == null) return;

    final diffMinutes = _calcDiffMinutes(parsed.start, parsed.end);
    final hours = diffMinutes / 60.0;

    _isSyncing = true;
    setState(() {
      _startTime = parsed.start;
      _endTime = parsed.end;
      widget.workHoursController.text = _formatHours(hours);
    });
    _isSyncing = false;
  }

  void _selectPreset(double hours) {
    widget.workHoursController.text = _formatHours(hours);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'SELECT SHIFT START TIME',
    );
    if (picked != null && mounted) {
      _isSyncing = true;
      setState(() {
        _startTime = picked;
        // Adjust end time based on currently configured work hours
        final hours =
            double.tryParse(widget.workHoursController.text.trim()) ?? 8.0;
        final startMinutes = picked.hour * 60 + picked.minute;
        final endMinutes = (startMinutes + (hours * 60).round()) % 1440;
        _endTime = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
        widget.shiftHoursController.text =
            '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}';
      });
      _isSyncing = false;
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'SELECT SHIFT END TIME',
    );
    if (picked != null && mounted) {
      _isSyncing = true;
      setState(() {
        _endTime = picked;
        // Recalculate daily work hours based on difference
        final diffMinutes = _calcDiffMinutes(_startTime, picked);
        final hours = diffMinutes / 60.0;
        widget.workHoursController.text = _formatHours(hours);
        widget.shiftHoursController.text =
            '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}';
      });
      _isSyncing = false;
    }
  }

  String _formatHours(double h) {
    return h == h.roundToDouble() ? h.toInt().toString() : h.toStringAsFixed(1);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$minute $period';
  }

  static int _calcDiffMinutes(TimeOfDay start, TimeOfDay end) {
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    if (endMin >= startMin) {
      final diff = endMin - startMin;
      return diff == 0 ? 1440 : diff;
    } else {
      return (1440 - startMin) + endMin;
    }
  }

  static ({TimeOfDay start, TimeOfDay end})? _parseShiftRange(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length != 2) return null;

    final start = _parseTime(parts[0]);
    final end = _parseTime(parts[1]);
    if (start == null || end == null) return null;
    return (start: start, end: end);
  }

  static TimeOfDay? _parseTime(String raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?$')
        .firstMatch(raw.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final currentHours = double.tryParse(
      widget.workHoursController.text.trim(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Schedule & Shift',
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Configures daily working target and benchmarks attendance progress.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Quick Preset Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in _presetHours) ...[
                ChoiceChip(
                  label: Text('${_formatHours(preset)} hrs'),
                  selected:
                      currentHours != null &&
                      (currentHours - preset).abs() < 0.05,
                  onSelected: (_) => _selectPreset(preset),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Work Hours Input
        widget.feedback.anchor(
          MemberField.dailyWorkHours,
          AppTextField(
            controller: widget.workHoursController,
            label: widget.feedback.label(
              'Daily Work Hours',
              MemberField.dailyWorkHours,
            ),
            errorText: widget.feedback.errorFor(MemberField.dailyWorkHours),
            hintText: 'e.g. 8.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                widthFactor: 1.0,
                child: Text(
                  'hours',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Interactive Shift Start & Shift End Time Pickers
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTimePickerField(
                label: 'Shift Start',
                valueText: _formatTimeOfDay(_startTime),
                hintText: 'Start Time',
                prefixIcon: const Icon(Icons.schedule_rounded, size: 20),
                onTap: _pickStartTime,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTimePickerField(
                label: 'Shift End',
                valueText: _formatTimeOfDay(_endTime),
                hintText: 'End Time',
                prefixIcon: const Icon(Icons.timelapse_rounded, size: 20),
                onTap: _pickEndTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
