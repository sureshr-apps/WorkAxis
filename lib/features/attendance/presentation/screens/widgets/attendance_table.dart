import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_table_row.dart';

/// Table representation of attendance records for wide layouts, emitted as a
/// sliver so rows are built lazily inside the page's [CustomScrollView].
class AttendanceTable extends StatelessWidget {
  const AttendanceTable({
    super.key,
    required this.entries,
    required this.getBranchName,
    required this.canReview,
    required this.isSaving,
    required this.onReview,
    required this.onDetails,
  });

  final List<AttendanceEntry> entries;
  final String Function(String branchId) getBranchName;
  final bool canReview;
  final bool isSaving;
  final void Function(AttendanceEntry entry, AttendanceReviewDecision decision)?
  onReview;
  final ValueChanged<AttendanceEntry> onDetails;

  static const _side = BorderSide(color: AppColors.kpiBorder);

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: _header()),
        SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
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
                entry: entry,
                branchName: getBranchName(entry.branchId),
                canReview: canReview,
                isSaving: isSaving,
                onReview: onReview,
                onDetails: () => onDetails(entry),
              ),
            );
          },
        ),
        SliverToBoxAdapter(child: _footer(entries.length)),
      ],
    );
  }

  Widget _header() {
    return Container(
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
            child: _HeaderLabel('EMPLOYEE'),
          ),
          Expanded(
            flex: AttendanceTableColumns.branch,
            child: _HeaderLabel('BRANCH / HUB'),
          ),
          Expanded(
            flex: AttendanceTableColumns.checkIn,
            child: _HeaderLabel('CHECK IN'),
          ),
          Expanded(
            flex: AttendanceTableColumns.checkOut,
            child: _HeaderLabel('CHECK OUT'),
          ),
          Expanded(
            flex: AttendanceTableColumns.method,
            child: _HeaderLabel('METHOD'),
          ),
          Expanded(
            flex: AttendanceTableColumns.status,
            child: _HeaderLabel('STATUS'),
          ),
          Expanded(
            flex: AttendanceTableColumns.review,
            child: _HeaderLabel('EXCEPTION & REVIEW'),
          ),
          SizedBox(
            width: AttendanceTableColumns.actions,
            child: _HeaderLabel('ACTIONS', alignEnd: true),
          ),
        ],
      ),
    );
  }

  Widget _footer(int count) {
    return Container(
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
        'Showing $count attendance records',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.kpiMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text, {this.alignEnd = false});

  final String text;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
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
}
