import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/attendance_presentation.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_method_badge.dart';

/// Card representation of an attendance record for smartphone and tablet
/// widths, replacing the wide table.
class AttendanceCardItem extends StatelessWidget {
  const AttendanceCardItem({
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
    final isNeedsReview = entry.needsReview;
    final hasNote = entry.note != null && entry.note!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isNeedsReview
              ? AppColors.statusPendingBorder
              : AppColors.outlineSubtle,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDetails,
          borderRadius: AppSpacing.roundedMd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topRow(),
                const SizedBox(height: AppSpacing.md),
                _infoPanel(),
                if (isNeedsReview || hasNote) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _noticeBanner(),
                ],
                const SizedBox(height: AppSpacing.sm),
                _actionRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            entry.initials,
            style: AppTypography.labelMedium.copyWith(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                entry.employeeId,
                style: AppTypography.labelMono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusChip(label: entry.status.label, type: entry.status.chipType),
      ],
    );
  }

  Widget _infoPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.outlineSubtle),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              AttendanceMethodBadge(entry: entry),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(height: 1, color: AppColors.outlineSubtle),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _TimeLabel(
                  icon: Icons.login_rounded,
                  iconColor: AppColors.statusActive,
                  prefix: 'In',
                  time: entry.checkInAt,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _TimeLabel(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.secondary,
                  prefix: 'Out',
                  time: entry.checkOutAt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _noticeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.statusPendingContainer,
        borderRadius: AppSpacing.roundedXs,
        border: Border.all(color: AppColors.statusPendingBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: AppColors.statusPendingText,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              entry.note ?? 'Needs supervisor verification',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.statusPendingText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow() {
    final showReview = canReview && entry.needsReview && onReview != null;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        if (showReview)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              AppButton.secondary(
                text: 'Verify',
                iconData: Icons.check,
                isFullWidth: false,
                onPressed: isSaving
                    ? null
                    : () => onReview!(entry, AttendanceReviewDecision.verify),
              ),
              AppButton.outlined(
                text: 'Dismiss',
                iconData: Icons.close,
                isFullWidth: false,
                onPressed: isSaving
                    ? null
                    : () => onReview!(entry, AttendanceReviewDecision.dismiss),
              ),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Details',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({
    required this.icon,
    required this.iconColor,
    required this.prefix,
    required this.time,
  });

  final IconData icon;
  final Color iconColor;
  final String prefix;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            '$prefix: ${AppFormatters.formatTime(time, placeholder: '—')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
