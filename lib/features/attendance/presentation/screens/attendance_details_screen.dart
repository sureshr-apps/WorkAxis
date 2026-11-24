import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/attendance_presentation.dart';
import 'package:workaxis/features/attendance/presentation/attendance_session_presentation.dart';
import 'package:workaxis/features/attendance/presentation/attendance_time_format.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/attendance_session_details_card.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Read-only daily summary with the underlying sessions listed independently.
class AttendanceDetailsScreen extends StatelessWidget {
  const AttendanceDetailsScreen({
    super.key,
    required this.summary,
    required this.branchNameFor,
    required this.backLabel,
    required this.onClose,
    required this.canReview,
    required this.isSaving,
    required this.onReview,
  });

  final AttendanceDaySummary summary;
  final String Function(String branchId) branchNameFor;
  final String backLabel;
  final VoidCallback onClose;
  final bool canReview;
  final bool isSaving;
  final Future<void> Function(
    AttendanceEntry entry,
    AttendanceReviewDecision decision,
  )?
  onReview;

  @override
  Widget build(BuildContext context) {
    final branches = summary.branchIds.map(branchNameFor).join(', ');
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            context.isCompact ? AppSpacing.md : AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageBreadcrumb(
                    backLabel: backLabel,
                    currentLabel: 'Attendance details',
                    onBack: onClose,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPageHeader(
                    eyebrow: 'Time & Attendance',
                    title: summary.employeeName,
                    subtitle:
                        '${AppFormatters.formatDate(summary.workDate)} · '
                        '${summary.sessions.length} attendance session(s)',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DashboardSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily summary', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        _SummaryDetail(label: 'Branches', value: branches),
                        _SummaryDetail(
                          label: 'First check-in',
                          value: AttendanceTimeFormat.time(
                            summary.firstCheckIn,
                          ),
                        ),
                        _SummaryDetail(
                          label: 'Last check-out',
                          value: summary.lastCheckOutLabel,
                        ),
                        if (summary.shiftWindowLabel != null)
                          _SummaryDetail(
                            label: 'Shift',
                            value: summary.shiftWindowLabel!,
                          ),
                        if (summary.overtimeLabel != null)
                          _SummaryDetail(
                            label: 'Overtime',
                            value: summary.overtimeLabel!,
                          ),
                        _SummaryDetail(
                          label: 'Daily status',
                          value: summary.status.label,
                        ),
                        if (summary.needsReviewCount > 0)
                          _SummaryDetail(
                            label: 'Needs review',
                            value: '${summary.needsReviewCount} session(s)',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Session history', style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  for (
                    var index = 0;
                    index < summary.sessions.length;
                    index++
                  ) ...[
                    AttendanceSessionDetailsCard(
                      index: index + 1,
                      entry: summary.sessions[index],
                      branchName: branchNameFor(
                        summary.sessions[index].branchId,
                      ),
                      canReview: canReview,
                      isSaving: isSaving,
                      onReview: onReview,
                    ),
                    if (index + 1 < summary.sessions.length)
                      const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryDetail extends StatelessWidget {
  const _SummaryDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: AppTypography.bodyMedium)),
      ],
    ),
  );
}
