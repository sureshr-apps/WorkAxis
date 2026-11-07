import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_card_item.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_table.dart';

/// Lazily built attendance records: a table on wide content, a two-column
/// card list on medium content and a single column on compact content.
/// Chosen from the width actually available to the sliver.
class AttendanceRecordsSliver extends StatelessWidget {
  const AttendanceRecordsSliver({
    super.key,
    required this.entries,
    required this.branchNameFor,
    required this.canReview,
    required this.isSaving,
    required this.onReview,
    required this.onDetails,
  });

  final List<AttendanceEntry> entries;
  final String Function(String branchId) branchNameFor;
  final bool canReview;
  final bool isSaving;
  final void Function(AttendanceEntry entry, AttendanceReviewDecision decision)?
  onReview;
  final ValueChanged<AttendanceEntry> onDetails;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        if (width >= AppBreakpoints.wideTable) {
          return AttendanceTable(
            entries: entries,
            getBranchName: branchNameFor,
            canReview: canReview,
            isSaving: isSaving,
            onReview: onReview,
            onDetails: onDetails,
          );
        }
        final columns = width >= AppBreakpoints.formSplit ? 2 : 1;
        final rowCount = (entries.length / columns).ceil();
        return SliverList.builder(
          itemCount: rowCount,
          itemBuilder: (context, rowIndex) {
            final start = rowIndex * columns;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: start + c < entries.length
                          ? _card(entries[start + c])
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
  }

  Widget _card(AttendanceEntry entry) => AttendanceCardItem(
    key: ValueKey(entry.id),
    entry: entry,
    branchName: branchNameFor(entry.branchId),
    canReview: canReview,
    isSaving: isSaving,
    onReview: onReview,
    onDetails: () => onDetails(entry),
  );
}
