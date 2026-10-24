import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';

/// Pixel-perfect Today's Attendance breakdown card for operational dashboards.
/// Adheres strictly to the Stitch specification (STITCH_FIDELITY_RULES.md).
class AttendanceSummaryCard extends StatelessWidget {
  final AttendanceSummary attendance;
  final List<BranchAdherenceSnapshot> branchSnapshots;
  final VoidCallback? onViewDetails;

  const AttendanceSummaryCard({
    super.key,
    required this.attendance,
    this.branchSnapshots = const [],
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;
    final totalScheduled = attendance.totalScheduled > 0
        ? attendance.totalScheduled
        : (attendance.present +
              attendance.late +
              attendance.absent +
              attendance.onLeave);
    final safeTotal = totalScheduled > 0 ? totalScheduled : 1;

    final presentRatio = (attendance.present / safeTotal).clamp(0.0, 1.0);
    final lateRatio = (attendance.late / safeTotal).clamp(0.0, 1.0);
    final absentRatio = (attendance.absent / safeTotal).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A191C20),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Action Link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Attendance",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Operational roll-call & roster distribution across daytime cycle',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: onViewDetails,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View full roster',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Attendance Multi-segment Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (presentRatio * 1000).toInt(),
                    child: Container(color: AppColors.statusActive),
                  ),
                  Expanded(
                    flex: (lateRatio * 1000).toInt(),
                    child: Container(color: AppColors.statusPending),
                  ),
                  Expanded(
                    flex: (absentRatio * 1000).toInt(),
                    child: Container(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),

          // Shift Window & Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Shift 01 & 02 Window',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Target: 95.0% adherence',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const SizedBox(height: AppSpacing.lg),

          // 4-Stat Metric Tonal Cards Grid
          LayoutBuilder(
            builder: (context, cardConstraints) {
              final useTwoColumns = cardConstraints.maxWidth < 620;
              if (useTwoColumns) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTonalMetricCard(
                            dotColor: AppColors.statusActive,
                            labelColor: AppColors.statusActiveText,
                            label: 'Present',
                            value: '${attendance.present}',
                            subtext:
                                '${(presentRatio * 100).toStringAsFixed(1)}% on-time',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildTonalMetricCard(
                            dotColor: AppColors.statusPending,
                            labelColor: AppColors.statusPendingText,
                            label: 'Late',
                            value: '${attendance.late}',
                            subtext:
                                '${(lateRatio * 100).toStringAsFixed(1)}% delayed',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTonalMetricCard(
                            dotColor: AppColors.error,
                            labelColor: AppColors.statusUrgentText,
                            label: 'Absent',
                            value: '${attendance.absent}',
                            subtext:
                                '${(absentRatio * 100).toStringAsFixed(1)}% unexcused',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildTonalMetricCard(
                            dotColor: AppColors.outline,
                            labelColor: AppColors.secondary,
                            label: 'On Leave',
                            value: '${attendance.onLeave}',
                            subtext: 'Medical / PTO',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildTonalMetricCard(
                      dotColor: AppColors.statusActive,
                      labelColor: AppColors.statusActiveText,
                      label: 'Present',
                      value: '${attendance.present}',
                      subtext:
                          '${(presentRatio * 100).toStringAsFixed(1)}% on-time',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildTonalMetricCard(
                      dotColor: AppColors.statusPending,
                      labelColor: AppColors.statusPendingText,
                      label: 'Late',
                      value: '${attendance.late}',
                      subtext:
                          '${(lateRatio * 100).toStringAsFixed(1)}% delayed',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildTonalMetricCard(
                      dotColor: AppColors.error,
                      labelColor: AppColors.statusUrgentText,
                      label: 'Absent',
                      value: '${attendance.absent}',
                      subtext:
                          '${(absentRatio * 100).toStringAsFixed(1)}% unexcused',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildTonalMetricCard(
                      dotColor: AppColors.outline,
                      labelColor: AppColors.secondary,
                      label: 'On Leave',
                      value: '${attendance.onLeave}',
                      subtext: 'Medical / PTO',
                    ),
                  ),
                ],
              );
            },
          ),

          // Key Branch Adherence Snapshot (shown when branch snapshots exist)
          if (branchSnapshots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Key Branch Adherence Snapshot',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Updated 12m ago',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, snapshotConstraints) {
                return Column(
                  children: _buildBranchSnapshotRows(
                    branchSnapshots,
                    showBar: snapshotConstraints.maxWidth >= 420,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTonalMetricCard({
    required Color dotColor,
    required Color labelColor,
    required String label,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.secondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBranchSnapshotRows(
    List<BranchAdherenceSnapshot> snapshots, {
    bool showBar = true,
  }) {
    final effectiveSnapshots = snapshots.isNotEmpty
        ? snapshots
        : const [
            BranchAdherenceSnapshot(
              code: 'CH',
              name: 'Central Distribution Hub',
              details: '182 of 185 present • Zone 1',
              adherenceRate: 0.984,
              adherencePercentage: '98.4%',
            ),
            BranchAdherenceSnapshot(
              code: 'ED',
              name: 'East River Cargo Depot',
              details: '122 of 134 present • Zone 2',
              adherenceRate: 0.910,
              adherencePercentage: '91.0%',
            ),
            BranchAdherenceSnapshot(
              code: 'SB',
              name: 'South Bay Logistics Yard',
              details: '85 of 109 present • Zone 3',
              adherenceRate: 0.780,
              adherencePercentage: '78.0%',
            ),
          ];

    return effectiveSnapshots.map((branch) {
      final isHigh = branch.adherenceRate >= 0.90;
      final badgeBg = isHigh
          ? AppColors.statusActiveContainer
          : AppColors.statusPendingContainer;
      final badgeText = isHigh
          ? AppColors.statusActiveText
          : AppColors.statusPendingText;
      final progressColor = isHigh
          ? AppColors.statusActive
          : AppColors.statusPending;

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          branch.code,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            branch.details,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showBar) ...[
                    Container(
                      width: 72,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: branch.adherenceRate.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      branch.adherencePercentage,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

/// Quick Operational Shift Notice Card below Today's Attendance.
class EveningShiftTransitionCard extends StatelessWidget {
  const EveningShiftTransitionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A191C20),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.access_time,
                      size: 20,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evening Shift Transition',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Scheduled in 2 hours 45 minutes across 8 primary gates',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '16:00 CST',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
