import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/presentation/attendance_presentation.dart';
import 'package:workaxis/features/attendance/presentation/attendance_session_presentation.dart';
import 'package:workaxis/features/attendance/presentation/attendance_time_format.dart';

/// Column flex weights shared by the daily summary table header and rows.
abstract final class AttendanceTableColumns {
  static const int employee = 4;
  static const int branches = 4;
  static const int checkIn = 3;
  static const int checkOut = 3;
  static const int sessions = 2;
  static const int status = 2;
  static const int review = 3;
  static const double actions = 132;
}

/// A single employee/day summary rendered as a wide attendance table row.
class AttendanceTableRow extends StatelessWidget {
  const AttendanceTableRow({
    super.key,
    required this.summary,
    required this.branchNames,
    required this.onDetails,
  });

  final AttendanceDaySummary summary;
  final String branchNames;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onDetails,
      hoverColor: AppColors.surfaceContainerLow,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              flex: AttendanceTableColumns.employee,
              child: _EmployeeCell(summary: summary),
            ),
            Expanded(
              flex: AttendanceTableColumns.branches,
              child: Text(
                branchNames,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.kpiLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: AttendanceTableColumns.checkIn,
              child: _TimeCell(
                label: AttendanceTimeFormat.time(summary.firstCheckIn),
                shiftWindow: summary.shiftWindowLabel,
              ),
            ),
            Expanded(
              flex: AttendanceTableColumns.checkOut,
              child: _CheckOutCell(summary: summary),
            ),
            Expanded(
              flex: AttendanceTableColumns.sessions,
              child: Text(
                '${summary.sessions.length}',
                style: AppTypography.labelMono,
              ),
            ),
            Expanded(
              flex: AttendanceTableColumns.status,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusChip(
                  label: summary.status.label,
                  type: summary.status.chipType,
                ),
              ),
            ),
            Expanded(
              flex: AttendanceTableColumns.review,
              child: _ReviewCell(summary: summary),
            ),
            SizedBox(
              width: AttendanceTableColumns.actions,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Sessions'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmployeeCell extends StatelessWidget {
  const _EmployeeCell({required this.summary});

  final AttendanceDaySummary summary;

  String get _initials {
    final parts = summary.employeeName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.substring(0, 1);
    final last = parts.length == 1 ? '' : parts.last.substring(0, 1);
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: AppSpacing.roundedSm,
        ),
        alignment: Alignment.center,
        child: Text(
          _initials,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.employeeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.kpiValue,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              AppFormatters.formatDate(summary.workDate),
              style: AppTypography.labelMono.copyWith(
                fontSize: 11,
                color: AppColors.kpiMuted,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({required this.label, this.shiftWindow});

  final String label;
  final String? shiftWindow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: AppTypography.labelMono),
      if (shiftWindow != null)
        Text(
          shiftWindow!,
          style: AppTypography.labelSmall.copyWith(color: AppColors.kpiMuted),
        ),
    ],
  );
}

/// Last check-out with its state chip (overdue, missing, late, corrected).
class _CheckOutCell extends StatelessWidget {
  const _CheckOutCell({required this.summary});

  final AttendanceDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final state = summary.checkoutStateDisplay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(summary.lastCheckOutLabel, style: AppTypography.labelMono),
        if (state != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          StatusChip(label: state.label, type: state.type, width: null),
        ],
      ],
    );
  }
}

/// Review count plus overtime awaiting or past approval.
class _ReviewCell extends StatelessWidget {
  const _ReviewCell({required this.summary});

  final AttendanceDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final pending = summary.needsReviewCount;
    final overtime = summary.overtimeLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          pending == 0 ? 'No review' : '$pending pending',
          style: AppTypography.bodySmall.copyWith(
            color: pending > 0
                ? AppColors.statusPendingText
                : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (overtime != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          StatusChip(
            label: overtime,
            type: summary.overtimeChipType,
            width: null,
          ),
        ],
      ],
    );
  }
}
