import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_table_row.dart';

/// Employee/day attendance summaries for wide layouts.
class AttendanceTable extends StatelessWidget {
  const AttendanceTable({
    super.key,
    required this.summaries,
    required this.getBranchNames,
    required this.onDetails,
  });

  final List<AttendanceDaySummary> summaries;
  final String Function(AttendanceDaySummary summary) getBranchNames;
  final ValueChanged<AttendanceDaySummary> onDetails;

  static const _side = BorderSide(color: AppColors.kpiBorder);

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(child: _header()),
      SliverList.builder(
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          final summary = summaries[index];
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                left: _side,
                right: _side,
                top: index > 0
                    ? const BorderSide(color: AppColors.kpiNeutralBackground)
                    : BorderSide.none,
              ),
            ),
            child: AttendanceTableRow(
              summary: summary,
              branchNames: getBranchNames(summary),
              onDetails: () => onDetails(summary),
            ),
          );
        },
      ),
      SliverToBoxAdapter(child: _footer(summaries.length)),
    ],
  );

  Widget _header() => Container(
    constraints: const BoxConstraints(minHeight: 44),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    decoration: const BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusMd),
      ),
      border: Border.fromBorderSide(_side),
    ),
    child: const Row(
      children: [
        Expanded(
          flex: AttendanceTableColumns.employee,
          child: _HeaderLabel('EMPLOYEE / DATE'),
        ),
        Expanded(
          flex: AttendanceTableColumns.branches,
          child: _HeaderLabel('BRANCHES'),
        ),
        Expanded(
          flex: AttendanceTableColumns.checkIn,
          child: _HeaderLabel('FIRST IN'),
        ),
        Expanded(
          flex: AttendanceTableColumns.checkOut,
          child: _HeaderLabel('LAST OUT'),
        ),
        Expanded(
          flex: AttendanceTableColumns.sessions,
          child: _HeaderLabel('SESSIONS'),
        ),
        Expanded(
          flex: AttendanceTableColumns.status,
          child: _HeaderLabel('STATUS'),
        ),
        Expanded(
          flex: AttendanceTableColumns.review,
          child: _HeaderLabel('REVIEW'),
        ),
        SizedBox(
          width: AttendanceTableColumns.actions,
          child: _HeaderLabel('DETAILS', alignEnd: true),
        ),
      ],
    ),
  );

  Widget _footer(int count) => Container(
    constraints: const BoxConstraints(minHeight: 44),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppSpacing.radiusMd),
      ),
      border: const Border.fromBorderSide(_side),
      boxShadow: AppShadows.card,
    ),
    child: Text(
      'Showing $count employee/day summaries',
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.kpiMuted,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text, {this.alignEnd = false});

  final String text;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
    child: Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.kpiMuted,
      ),
    ),
  );
}
