import 'package:flutter/material.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/checkout_correction.dart';
import 'package:workaxis/features/attendance/presentation/attendance_time_format.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/exception_review_tile_frame.dart';

/// A pending check-out correction: recorded vs requested check-out.
class CorrectionReviewTile extends StatelessWidget {
  const CorrectionReviewTile({
    super.key,
    required this.correction,
    required this.onApprove,
    required this.onReject,
  });

  final CheckoutCorrection correction;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final recorded = correction.recordedCheckOutAt;
    final checkIn = correction.checkInAt;
    return ExceptionReviewTileFrame(
      employeeName: correction.employeeName,
      chipLabel: recorded == null ? 'Missing check-out' : 'Late check-out',
      chipType: recorded == null ? StatusType.urgent : StatusType.pending,
      lines: [
        ExceptionReviewLine(
          label: 'Shift date',
          value: AppFormatters.formatDate(correction.workDate),
        ),
        ExceptionReviewLine(
          label: 'Check-in',
          value: checkIn == null
              ? '—'
              : AttendanceTimeFormat.timeOnShift(checkIn, correction.workDate),
        ),
        ExceptionReviewLine(
          label: 'Recorded check-out',
          value: recorded == null
              ? 'None (closed by system)'
              : AttendanceTimeFormat.timeOnShift(recorded, correction.workDate),
        ),
        ExceptionReviewLine(
          label: 'Requested check-out',
          value: AttendanceTimeFormat.timeOnShift(
            correction.requestedCheckOutAt,
            correction.workDate,
          ),
        ),
      ],
      note: correction.reason,
      onApprove: onApprove,
      onReject: onReject,
    );
  }
}
