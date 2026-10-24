import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';

/// Card presenting monthly attendance index, 3-metric strip, and 7-day adherence bars.
class AttendanceSummaryCard extends StatelessWidget {
  final EmployeeHomeSummary summary;
  final VoidCallback onViewHistory;

  const AttendanceSummaryCard({
    super.key,
    required this.summary,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 21,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Attendance Summary',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'October 2024',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Monthly Performance Metric
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '98.2%',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Target > 95% (Achieved)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusActiveText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Monthly Performance Index',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Key Metrics 3-Strip
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  count: '${summary.monthlyDaysPresent}',
                  label: 'Present',
                  color: AppColors.statusActiveText,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildMetricTile(
                  count: '${summary.monthlyDaysLate}',
                  label: 'Late',
                  color: AppColors.statusPendingText,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildMetricTile(
                  count: '${summary.monthlyDaysAbsent}',
                  label: 'Absent',
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Last 7 Shifts Compliance Header
          Text(
            'LAST 7 SHIFTS (F - S - S - M - T - W - T)',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // 7 Day Bars
          Row(
            children: [
              _buildDayShiftColumn(
                day: 'F',
                child: const Icon(
                  Icons.check,
                  size: 15,
                  color: AppColors.statusActiveText,
                ),
                bg: AppColors.statusActiveContainer,
              ),
              const SizedBox(width: 6),
              _buildDayShiftColumn(
                day: 'S',
                child: const Icon(
                  Icons.check,
                  size: 15,
                  color: AppColors.statusActiveText,
                ),
                bg: AppColors.statusActiveContainer,
              ),
              const SizedBox(width: 6),
              _buildDayShiftColumn(
                day: 'S',
                child: Text(
                  '—',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                bg: const Color(0xFFE2E8F0),
                isMuted: true,
              ),
              const SizedBox(width: 6),
              _buildDayShiftColumn(
                day: 'M',
                child: const Icon(
                  Icons.check,
                  size: 15,
                  color: AppColors.statusActiveText,
                ),
                bg: AppColors.statusActiveContainer,
              ),
              const SizedBox(width: 6),
              _buildDayShiftColumn(
                day: 'T',
                child: const Icon(
                  Icons.schedule,
                  size: 15,
                  color: AppColors.statusPendingText,
                ),
                bg: AppColors.statusPendingContainer,
                isPending: true,
              ),
              const SizedBox(width: 6),
              _buildDayShiftColumn(
                day: 'W',
                child: const Icon(
                  Icons.check,
                  size: 15,
                  color: AppColors.statusActiveText,
                ),
                bg: AppColors.statusActiveContainer,
              ),
              const SizedBox(width: 6),
              _buildDayShiftColumn(
                day: 'T',
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                bg: AppColors.primaryContainer,
                isToday: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // View History Link
          InkWell(
            onTap: onViewHistory,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View attendance history',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
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
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayShiftColumn({
    required String day,
    required Widget child,
    required Color bg,
    bool isMuted = false,
    bool isPending = false,
    bool isToday = false,
  }) {
    return Expanded(
      child: Opacity(
        opacity: isMuted ? 0.6 : 1.0,
        child: Column(
          children: [
            Text(
              day,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: isToday || isPending
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isToday
                    ? AppColors.primary
                    : isPending
                    ? AppColors.statusPendingText
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
