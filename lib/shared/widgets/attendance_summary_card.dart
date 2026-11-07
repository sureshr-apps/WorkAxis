import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';
import 'package:workaxis/shared/widgets/attendance_metric_tile.dart';
import 'package:workaxis/shared/widgets/branch_adherence_row.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Today's attendance breakdown shared by the organization and branch
/// dashboards. Every figure is derived from [attendance] and
/// [branchSnapshots]; nothing is fabricated.
class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({
    super.key,
    required this.attendance,
    this.branchSnapshots = const [],
    this.onViewDetails,
  });

  final AttendanceSummary attendance;
  final List<BranchAdherenceSnapshot> branchSnapshots;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onViewDetails: onViewDetails),
          const SizedBox(height: AppSpacing.lg),
          _DistributionBar(attendance: attendance),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            'Attendance rate: ${attendance.attendancePercentage}% of '
            '${attendance.distributionTotal} scheduled',
            style: AppTypography.labelMono.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MetricTiles(attendance: attendance),
          if (branchSnapshots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Key Branch Adherence Snapshot',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  for (final snapshot in branchSnapshots)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: BranchAdherenceRow(
                        snapshot: snapshot,
                        showBar:
                            constraints.maxWidth >=
                            AppBreakpoints.snapshotBarMin,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Formats a 0..1 share for the metric captions, e.g. 12.5%.
  static String share(double value) => '${(value * 100).toStringAsFixed(1)}%';
}

class _Header extends StatelessWidget {
  const _Header({this.onViewDetails});

  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Attendance",
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              'Roster distribution for today',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        if (onViewDetails != null)
          AppButton.outlined(
            text: 'View full roster',
            iconData: Icons.arrow_forward,
            isFullWidth: false,
            onPressed: onViewDetails,
          ),
      ],
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.attendance});

  final AttendanceSummary attendance;

  @override
  Widget build(BuildContext context) {
    int flex(double share) => (share * 1000).round();
    final segments = <(int, Color)>[
      (flex(attendance.presentShare), AppColors.statusActive),
      (flex(attendance.lateShare), AppColors.statusPending),
      (flex(attendance.absentShare), AppColors.error),
    ].where((segment) => segment.$1 > 0).toList();

    return Semantics(
      label:
          'Attendance distribution: ${attendance.present} present, '
          '${attendance.late} late, ${attendance.absent} absent',
      child: ClipRRect(
        borderRadius: AppSpacing.roundedPill,
        child: SizedBox(
          height: 12,
          child: Row(
            children: [
              for (final segment in segments)
                Expanded(
                  flex: segment.$1,
                  child: ColoredBox(color: segment.$2),
                ),
              if (segments.isEmpty)
                const Expanded(
                  child: ColoredBox(color: AppColors.surfaceContainerHigh),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTiles extends StatelessWidget {
  const _MetricTiles({required this.attendance});

  final AttendanceSummary attendance;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      AttendanceMetricTile(
        dotColor: AppColors.statusActive,
        labelColor: AppColors.statusActiveText,
        label: 'Present',
        value: '${attendance.present}',
        caption:
            '${AttendanceSummaryCard.share(attendance.presentShare)} of scheduled',
      ),
      AttendanceMetricTile(
        dotColor: AppColors.statusPending,
        labelColor: AppColors.statusPendingText,
        label: 'Late',
        value: '${attendance.late}',
        caption:
            '${AttendanceSummaryCard.share(attendance.lateShare)} of scheduled',
      ),
      AttendanceMetricTile(
        dotColor: AppColors.error,
        labelColor: AppColors.statusUrgentText,
        label: 'Absent',
        value: '${attendance.absent}',
        caption:
            '${AttendanceSummaryCard.share(attendance.absentShare)} of scheduled',
      ),
      AttendanceMetricTile(
        dotColor: AppColors.outline,
        labelColor: AppColors.secondary,
        label: 'On Leave',
        value: attendance.onLeave?.toString() ?? '—',
        caption: attendance.onLeave == null ? 'Not tracked' : 'Approved leave',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < AppBreakpoints.metricTilesRow
            ? 2
            : 4;
        final rows = <Widget>[];
        for (var i = 0; i < tiles.length; i += columns) {
          final slice = tiles.skip(i).take(columns).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < slice.length; j++) ...[
                    if (j > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: slice[j]),
                  ],
                ],
              ),
            ),
          );
          if (i + columns < tiles.length) {
            rows.add(const SizedBox(height: AppSpacing.sm));
          }
        }
        return Column(children: rows);
      },
    );
  }
}
