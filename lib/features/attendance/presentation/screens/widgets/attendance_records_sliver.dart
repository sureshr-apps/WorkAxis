import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_card_item.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_table.dart';

/// Lazily builds one attendance item per employee and business date.
class AttendanceRecordsSliver extends StatelessWidget {
  const AttendanceRecordsSliver({
    super.key,
    required this.summaries,
    required this.branchNamesFor,
    required this.onDetails,
  });

  final List<AttendanceDaySummary> summaries;
  final String Function(AttendanceDaySummary summary) branchNamesFor;
  final ValueChanged<AttendanceDaySummary> onDetails;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.crossAxisExtent;
      if (width >= AppBreakpoints.wideTable) {
        return AttendanceTable(
          summaries: summaries,
          getBranchNames: branchNamesFor,
          onDetails: onDetails,
        );
      }
      final columns = width >= AppBreakpoints.formSplit ? 2 : 1;
      final rowCount = (summaries.length / columns).ceil();
      return SliverList.builder(
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          final start = rowIndex * columns;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var column = 0; column < columns; column++) ...[
                  if (column > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: start + column < summaries.length
                        ? _card(summaries[start + column])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );

  Widget _card(AttendanceDaySummary summary) => AttendanceCardItem(
    key: ValueKey(summary.id),
    summary: summary,
    branchNames: branchNamesFor(summary),
    onDetails: () => onDetails(summary),
  );
}
