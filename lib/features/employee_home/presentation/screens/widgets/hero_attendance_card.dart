import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/presentation/attendance_status_presentation.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/hero_metric.dart';

/// Hero attendance card: shift, check-in/out telemetry, progress and the
/// primary attendance action. Every value comes from [EmployeeHomeSummary].
class HeroAttendanceCard extends StatelessWidget {
  const HeroAttendanceCard({
    super.key,
    required this.summary,
    required this.isProcessing,
    required this.onPrimaryAction,
  });

  final EmployeeHomeSummary summary;
  final bool isProcessing;
  final VoidCallback onPrimaryAction;

  static bool _has(String? value) =>
      value != null &&
      value.isNotEmpty &&
      value != EmployeeHomeSummary.unavailable;

  @override
  Widget build(BuildContext context) {
    final status = summary.currentStatus;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.kpiBorder),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 6, color: status.ribbonColor),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(status),
                const SizedBox(height: AppSpacing.lg),
                _telemetry(status),
                const SizedBox(height: AppSpacing.lg),
                _progress(status),
                const SizedBox(height: AppSpacing.lg),
                _actionSurface(status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AttendanceStatus status) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SHIFT VERIFICATION',
                style: AppTypography.labelMono.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${summary.shiftName} • ${summary.shiftHours}',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_has(summary.standardDuration)) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Standard Duration: ${summary.standardDuration}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusChip(label: status.pillLabel, type: status.chipType, width: null),
      ],
    );
  }

  Widget _telemetry(AttendanceStatus status) {
    final hasCheckOut = _has(summary.checkOutTime);
    final divider = Container(
      height: 36,
      width: 1,
      color: AppColors.kpiBorder,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.kpiBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: HeroMetric(
              label: 'Check-In',
              value: summary.checkInTime ?? '--:--',
              note: summary.checkInNote,
              noteColor: status == AttendanceStatus.checkedIn
                  ? AppColors.statusActiveText
                  : status == AttendanceStatus.onBreak
                  ? AppColors.statusPendingText
                  : AppColors.onSurfaceVariant,
            ),
          ),
          divider,
          Expanded(
            child: HeroMetric(
              label: 'Check-Out',
              value: summary.checkOutTime ?? '--:--',
              note: summary.checkOutNote,
              valueColor: hasCheckOut
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant,
              noteColor: status == AttendanceStatus.checkedOut
                  ? AppColors.statusActiveText
                  : AppColors.onSurfaceVariant,
            ),
          ),
          divider,
          Expanded(
            child: HeroMetric(
              label: 'Elapsed Active',
              value: summary.elapsedActive,
              note: _has(summary.elapsedActivePercentText)
                  ? summary.elapsedActivePercentText
                  : null,
              valueColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress(AttendanceStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Progress: ${summary.workingDuration} of ${summary.standardDuration}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${(summary.shiftProgress * 100).toStringAsFixed(1)}%',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppSpacing.roundedPill,
          child: LinearProgressIndicator(
            value: summary.shiftProgress.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: AppColors.kpiBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              status == AttendanceStatus.onBreak
                  ? AppColors.statusPendingText
                  : AppColors.primary,
            ),
          ),
        ),
        if (_has(summary.shiftHours)) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Scheduled ${summary.shiftHours}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMono.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionSurface(AttendanceStatus status) {
    final canAct = status.nextAction != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.kpiBorder),
      ),
      child: Column(
        children: [
          AppButton.primary(
            text: status.heroActionLabel,
            iconData: status.heroActionIcon,
            isLoading: isProcessing,
            onPressed: canAct ? onPrimaryAction : null,
          ),
          if (summary.locationStatus.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  summary.isWithinGeofence
                      ? Icons.location_on_outlined
                      : Icons.location_off_outlined,
                  size: 19,
                  color: summary.isWithinGeofence
                      ? AppColors.statusActiveText
                      : AppColors.statusUrgentText,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    [
                      summary.locationStatus,
                      if (_has(summary.terminalId))
                        'Terminal ${summary.terminalId}',
                    ].join(' • '),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
