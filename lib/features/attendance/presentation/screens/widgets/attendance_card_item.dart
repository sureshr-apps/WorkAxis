import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/presentation/attendance_presentation.dart';

/// Responsive card for one employee/day; underlying sessions open in details.
class AttendanceCardItem extends StatelessWidget {
  const AttendanceCardItem({
    super.key,
    required this.summary,
    required this.branchNames,
    required this.onDetails,
  });

  final AttendanceDaySummary summary;
  final String branchNames;
  final VoidCallback onDetails;

  String get _initials {
    final parts = summary.employeeName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length == 1
        ? parts.first.characters.first.toUpperCase()
        : '${parts.first.characters.first}${parts.last.characters.first}'
              .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final needsReview = summary.needsReviewCount > 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: needsReview
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        _initials,
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
                            summary.employeeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            AppFormatters.formatDate(summary.workDate),
                            style: AppTypography.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusChip(
                      label: summary.status.label,
                      type: summary.status.chipType,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoPanel(
                  branchNames: branchNames,
                  branchCount: summary.branchIds.length,
                  sessionCount: summary.sessions.length,
                  firstCheckIn: summary.firstCheckIn,
                  lastCheckOut: summary.lastCheckOut,
                ),
                if (needsReview) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.statusPendingText,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${summary.needsReviewCount} session(s) need review',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.statusPendingText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('View sessions'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.branchNames,
    required this.branchCount,
    required this.sessionCount,
    required this.firstCheckIn,
    required this.lastCheckOut,
  });

  final String branchNames;
  final int branchCount;
  final int sessionCount;
  final DateTime? firstCheckIn;
  final DateTime? lastCheckOut;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: AppSpacing.roundedSm,
      border: Border.all(color: AppColors.outlineSubtle),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 16,
              color: AppColors.secondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                branchNames,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$sessionCount session(s) · $branchCount branch(es)',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const Divider(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _TimeLabel(
                icon: Icons.login_rounded,
                label: 'First in',
                time: firstCheckIn,
              ),
            ),
            Expanded(
              child: _TimeLabel(
                icon: Icons.logout_rounded,
                label: 'Last out',
                time: lastCheckOut,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({
    required this.icon,
    required this.label,
    required this.time,
  });

  final IconData icon;
  final String label;
  final DateTime? time;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors.secondary),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text(
          '$label: ${AppFormatters.formatTime(time, placeholder: time == null ? 'In progress' : '—')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMono.copyWith(fontSize: 11),
        ),
      ),
    ],
  );
}
