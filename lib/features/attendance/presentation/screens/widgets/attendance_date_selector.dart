import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';

/// Today / Yesterday quick filters plus the selected date.
class AttendanceDateSelector extends StatelessWidget {
  const AttendanceDateSelector({
    super.key,
    required this.selectedDate,
    required this.today,
    required this.yesterday,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final DateTime today;
  final DateTime yesterday;
  final ValueChanged<DateTime> onSelected;

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final isToday = _same(selectedDate, today);
    final isYesterday = _same(selectedDate, yesterday);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _chip('Today', isToday, () => onSelected(today)),
        _chip('Yesterday', isYesterday, () => onSelected(yesterday)),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppSpacing.roundedSm,
            border: Border.all(color: AppColors.kpiBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppFormatters.formatDate(selectedDate),
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      selected: selected,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.outlineVariant,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
