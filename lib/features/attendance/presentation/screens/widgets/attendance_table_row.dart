import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/attendance_presentation.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_method_badge.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_review_badge.dart';

/// Column flex weights shared by the table header and rows.
abstract final class AttendanceTableColumns {
  static const int employee = 4;
  static const int branch = 3;
  static const int checkIn = 2;
  static const int checkOut = 2;
  static const int method = 3;
  static const int status = 3;
  static const int review = 4;
  static const double actions = 176;
}

/// A single attendance record rendered as a table row (desktop / wide tablet).
class AttendanceTableRow extends StatelessWidget {
  const AttendanceTableRow({
    super.key,
    required this.entry,
    required this.branchName,
    required this.canReview,
    required this.isSaving,
    required this.onReview,
    required this.onDetails,
  });

  final AttendanceEntry entry;
  final String branchName;
  final bool canReview;
  final bool isSaving;
  final void Function(AttendanceEntry entry, AttendanceReviewDecision decision)?
  onReview;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final showReviewActions =
        canReview && entry.needsReview && onReview != null;
    return Material(
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
                child: _EmployeeCell(entry: entry),
              ),
              Expanded(
                flex: AttendanceTableColumns.branch,
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 15,
                      color: AppColors.kpiMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        branchName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.kpiLabel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: AttendanceTableColumns.checkIn,
                child: _TimeCell(time: entry.checkInAt),
              ),
              Expanded(
                flex: AttendanceTableColumns.checkOut,
                child: _TimeCell(time: entry.checkOutAt),
              ),
              Expanded(
                flex: AttendanceTableColumns.method,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AttendanceMethodBadge(entry: entry),
                ),
              ),
              Expanded(
                flex: AttendanceTableColumns.status,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip(
                    label: entry.status.label,
                    type: entry.status.chipType,
                  ),
                ),
              ),
              Expanded(
                flex: AttendanceTableColumns.review,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AttendanceReviewBadge(status: entry.reviewStatus),
                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.kpiMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: AttendanceTableColumns.actions,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showReviewActions) ...[
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded),
                        color: AppColors.kpiPositiveAccent,
                        tooltip: 'Verify attendance',
                        onPressed: isSaving
                            ? null
                            : () => onReview!(
                                entry,
                                AttendanceReviewDecision.verify,
                              ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        color: AppColors.kpiMuted,
                        tooltip: 'Dismiss exception',
                        onPressed: isSaving
                            ? null
                            : () => onReview!(
                                entry,
                                AttendanceReviewDecision.dismiss,
                              ),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: AppColors.primary,
                      tooltip: 'View details',
                      onPressed: onDetails,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeCell extends StatelessWidget {
  const _EmployeeCell({required this.entry});

  final AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            entry.initials,
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
                entry.employeeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.kpiValue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                entry.employeeId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({required this.time});

  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    final recorded = time != null;
    return Text(
      AppFormatters.formatTime(time, placeholder: '—'),
      style: AppTypography.labelMono.copyWith(
        fontWeight: recorded ? FontWeight.w700 : FontWeight.w400,
        color: recorded ? AppColors.kpiValue : AppColors.textMuted,
      ),
    );
  }
}
