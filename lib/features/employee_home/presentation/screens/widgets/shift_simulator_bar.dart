import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';

/// Debug-only shift state simulator. The home screen renders it only when the
/// controller exposes a simulator (mock backend in debug builds).
class ShiftSimulatorBar extends StatelessWidget {
  const ShiftSimulatorBar({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  final AttendanceStatus currentStatus;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  static const _labels = <AttendanceStatus, String>{
    AttendanceStatus.notCheckedIn: 'Not Checked In',
    AttendanceStatus.checkedIn: 'Checked In (Active)',
    AttendanceStatus.onBreak: 'On Break',
    AttendanceStatus.checkedOut: 'Shift Completed',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!context.isCompact)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'Simulation:',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            for (final entry in _labels.entries)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: currentStatus == entry.key,
                  onSelected: (_) => onStatusChanged(entry.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
