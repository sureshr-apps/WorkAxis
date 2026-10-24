import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// Card representation of an attendance record designed for smartphone and tablet viewports.
/// Replaces the horizontal-scrolling 1150px table on compact and medium screens with a touch-friendly card.
class AttendanceCardItem extends StatelessWidget {
  final AttendanceEntry entry;
  final String branchName;
  final bool canReview;
  final bool isSaving;
  final void Function(AttendanceEntry entry, AttendanceReviewDecision decision)?
  onReview;
  final VoidCallback onDetails;

  const AttendanceCardItem({
    super.key,
    required this.entry,
    required this.branchName,
    required this.canReview,
    required this.isSaving,
    required this.onReview,
    required this.onDetails,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '—';
    return DateFormat('hh:mm a').format(time);
  }

  String get _initials {
    final parts = entry.employeeName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return entry.employeeName.isNotEmpty
        ? entry.employeeName[0].toUpperCase()
        : '?';
  }

  String get _statusLabel {
    switch (entry.status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.incomplete:
        return 'Incomplete';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNeedsReview =
        entry.reviewStatus == AttendanceReviewStatus.needsReview;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isNeedsReview
              ? AppColors.statusPending.withValues(alpha: 0.5)
              : AppColors.outlineSubtle,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDetails,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Name + ID on left, StatusChip on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        _initials,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.employeeName,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.employeeId,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusChip.fromStatus(
                      _statusLabel,
                      width: 96,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Middle Info Card: Branch, Check In/Out, Method
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: AppColors.outlineSubtle.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 15,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              branchName,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Method badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: entry.kioskEntry
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: entry.kioskEntry
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFFDBEAFE),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  entry.kioskEntry
                                      ? Icons.tablet_android_outlined
                                      : Icons.phone_android_outlined,
                                  size: 12,
                                  color: entry.kioskEntry
                                      ? const Color(0xFF475569)
                                      : const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  entry.kioskEntry ? 'Kiosk' : 'Mobile',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: entry.kioskEntry
                                      ? const Color(0xFF475569)
                                      : const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Divider(height: 1, color: AppColors.outlineSubtle),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.login_rounded,
                                  size: 13,
                                  color: AppColors.statusActive,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    'In: ${_formatTime(entry.checkInAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  size: 13,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    'Out: ${_formatTime(entry.checkOutAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Exception notice if present
                if (isNeedsReview || (entry.note != null && entry.note!.isNotEmpty)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusPendingContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      border: Border.all(color: AppColors.statusPendingBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.statusPendingText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.note ?? 'Shift anomaly needs supervisor verification',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.statusPendingText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.sm),

                // Bottom Action Bar: Quick Review actions (if manager/admin) + Details >
                Row(
                  children: [
                    if (canReview && isNeedsReview && onReview != null) ...[
                      InkWell(
                        onTap: isSaving
                            ? null
                            : () => onReview!(
                                entry,
                                AttendanceReviewDecision.verify,
                              ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXs),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check,
                                size: 12,
                                color: Color(0xFF15803D),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Verify',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      InkWell(
                        onTap: isSaving
                            ? null
                            : () => onReview!(
                                entry,
                                AttendanceReviewDecision.dismiss,
                              ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXs),
                            border: Border.all(color: AppColors.outlineSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.close,
                                size: 12,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Dismiss',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Details',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
