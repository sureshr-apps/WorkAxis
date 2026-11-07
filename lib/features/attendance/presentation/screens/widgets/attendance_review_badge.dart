import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// Review-state indicator used in the attendance table.
class AttendanceReviewBadge extends StatelessWidget {
  const AttendanceReviewBadge({super.key, required this.status});

  final AttendanceReviewStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      AttendanceReviewStatus.needsReview => const StatusChip(
        label: 'Needs review',
        type: StatusType.pending,
        width: null,
      ),
      AttendanceReviewStatus.verified => const StatusChip(
        label: 'Verified',
        type: StatusType.active,
        width: null,
      ),
      AttendanceReviewStatus.dismissed => const StatusChip(
        label: 'Reviewed',
        type: StatusType.neutral,
        width: null,
      ),
      AttendanceReviewStatus.none => Text(
        '—',
        semanticsLabel: 'No review required',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      ),
    };
  }
}
