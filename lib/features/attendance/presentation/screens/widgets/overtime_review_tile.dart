import 'package:flutter/material.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/attendance_session_presentation.dart';
import 'package:workaxis/features/attendance/presentation/attendance_time_format.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/exception_review_tile_frame.dart';

/// A session with overtime waiting for approval: scheduled vs worked hours.
class OvertimeReviewTile extends StatelessWidget {
  const OvertimeReviewTile({
    super.key,
    required this.entry,
    required this.onApprove,
    required this.onReject,
  });

  final AttendanceEntry entry;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final scheduled = entry.scheduledHours;
    final worked = entry.workedDuration;
    final shift = entry.shiftWindowLabel;
    return ExceptionReviewTileFrame(
      employeeName: entry.employeeName,
      chipLabel:
          '${AttendanceTimeFormat.hours(entry.potentialOvertimeHours)} '
          'potential OT',
      chipType: StatusType.pending,
      lines: [
        ExceptionReviewLine(
          label: 'Shift date',
          value: AppFormatters.formatDate(entry.workDate),
        ),
        if (shift != null)
          ExceptionReviewLine(
            label: 'Scheduled shift',
            value: shift.replaceFirst('Shift ', ''),
          ),
        ExceptionReviewLine(
          label: 'Check-in / out',
          value:
              '${AttendanceTimeFormat.time(entry.checkInAt)} – '
              '${entry.checkOutLabel}',
        ),
        ExceptionReviewLine(
          label: 'Scheduled hours',
          value: scheduled == null
              ? '—'
              : AttendanceTimeFormat.hours(scheduled),
        ),
        ExceptionReviewLine(
          label: 'Worked hours',
          value: worked == null
              ? '—'
              : AttendanceTimeFormat.hours(worked.inMinutes / 60),
        ),
      ],
      onApprove: onApprove,
      onReject: onReject,
    );
  }
}
