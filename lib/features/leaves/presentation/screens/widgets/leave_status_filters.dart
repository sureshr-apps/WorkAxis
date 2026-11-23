import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_status_counts.dart';

/// "All" plus one chip per status, labelled with the server counts of the
/// current queue.
class LeaveStatusFilters extends StatelessWidget {
  const LeaveStatusFilters({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.counts,
  });

  final LeaveStatus? selected;
  final ValueChanged<LeaveStatus?> onSelected;
  final LeaveStatusCounts counts;

  @override
  Widget build(BuildContext context) {
    final filters = [
      FilterChip(
        label: Text('All (${counts.total})'),
        selected: selected == null,
        onSelected: (_) => onSelected(null),
      ),
      for (final status in LeaveStatus.values)
        FilterChip(
          label: Text('${status.label} (${counts.of(status)})'),
          selected: selected == status,
          onSelected: (_) => onSelected(status),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            filters[index],
          ],
        ],
      ),
    );
  }
}
