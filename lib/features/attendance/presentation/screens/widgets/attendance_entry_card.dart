import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

class AttendanceEntryCard extends StatelessWidget {
  const AttendanceEntryCard({
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
  final ValueChanged<AttendanceReviewDecision>? onReview;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final status = switch (entry.status) {
      AttendanceStatus.present => 'Present',
      AttendanceStatus.late => 'Late',
      AttendanceStatus.absent => 'Absent',
      AttendanceStatus.incomplete => 'Incomplete',
    };
    final review = switch (entry.reviewStatus) {
      AttendanceReviewStatus.none => null,
      AttendanceReviewStatus.needsReview => 'Needs review',
      AttendanceReviewStatus.verified => 'Verified',
      AttendanceReviewStatus.dismissed => 'Reviewed',
    };
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineSubtle),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: status,
                    type: switch (entry.status) {
                      AttendanceStatus.present => StatusType.active,
                      AttendanceStatus.late => StatusType.pending,
                      AttendanceStatus.absent ||
                      AttendanceStatus.incomplete => StatusType.urgent,
                    },
                    width: 96,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.store_outlined,
                    size: 15,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      branchName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    entry.kioskEntry
                        ? Icons.tablet_android_outlined
                        : Icons.phone_android_outlined,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    entry.kioskEntry ? 'Kiosk' : 'Mobile',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _Time(
                      label: 'CHECK IN',
                      value: _formatTime(entry.checkInAt),
                    ),
                  ),
                  Expanded(
                    child: _Time(
                      label: 'CHECK OUT',
                      value: _formatTime(entry.checkOutAt),
                    ),
                  ),
                  if (review != null)
                    StatusChip(
                      label: review,
                      type:
                          entry.reviewStatus ==
                              AttendanceReviewStatus.needsReview
                          ? StatusType.pending
                          : StatusType.neutral,
                      width: 96,
                    ),
                ],
              ),
              if (entry.note != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  entry.note!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              if (canReview &&
                  entry.reviewStatus == AttendanceReviewStatus.needsReview) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outlined(
                        text: 'Dismiss',
                        isLoading: isSaving,
                        onPressed: () =>
                            onReview?.call(AttendanceReviewDecision.dismiss),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton.primary(
                        text: 'Verify',
                        isLoading: isSaving,
                        onPressed: () =>
                            onReview?.call(AttendanceReviewDecision.verify),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Time extends StatelessWidget {
  const _Time({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    ],
  );
}

String _formatTime(DateTime? time) => time == null
    ? '—'
    : '${time.hour > 12
          ? time.hour - 12
          : time.hour == 0
          ? 12
          : time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
