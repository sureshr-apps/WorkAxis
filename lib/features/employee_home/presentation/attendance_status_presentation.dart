import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';

/// Flutter visuals for the domain [AttendanceStatus].
extension AttendanceStatusPresentation on AttendanceStatus {
  /// Short label for the hero status pill.
  String get pillLabel => switch (this) {
    AttendanceStatus.notCheckedIn => 'Not Checked In',
    AttendanceStatus.checkedIn => 'Checked In',
    AttendanceStatus.onBreak => 'On Meal Break',
    AttendanceStatus.checkedOut => 'Shift Completed',
  };

  StatusType get chipType => switch (this) {
    AttendanceStatus.notCheckedIn => StatusType.neutral,
    AttendanceStatus.checkedIn => StatusType.active,
    AttendanceStatus.onBreak => StatusType.pending,
    AttendanceStatus.checkedOut => StatusType.active,
  };

  Color get ribbonColor => switch (this) {
    AttendanceStatus.notCheckedIn => AppColors.outline,
    AttendanceStatus.checkedIn => AppColors.statusActiveText,
    AttendanceStatus.onBreak => AppColors.statusPendingText,
    AttendanceStatus.checkedOut => AppColors.primary,
  };

  /// Label of the primary hero action for this status.
  String get heroActionLabel => switch (this) {
    AttendanceStatus.notCheckedIn => 'Check In Now',
    AttendanceStatus.checkedIn => 'Start Break',
    AttendanceStatus.onBreak => 'Resume Shift',
    AttendanceStatus.checkedOut => 'Shift Logged (Done for Today)',
  };

  IconData get heroActionIcon => switch (this) {
    AttendanceStatus.notCheckedIn => Icons.login,
    AttendanceStatus.checkedIn => Icons.local_cafe_outlined,
    AttendanceStatus.onBreak => Icons.play_arrow_rounded,
    AttendanceStatus.checkedOut => Icons.done_all,
  };
}
