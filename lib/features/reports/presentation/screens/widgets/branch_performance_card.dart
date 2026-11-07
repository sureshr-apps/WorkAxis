import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/content_width_scope.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/presentation/report_presentation.dart';
import 'package:workaxis/features/reports/presentation/screens/widgets/report_section_card.dart';

/// Per-branch attendance, headcount and exception figures.
class BranchPerformanceCard extends StatelessWidget {
  const BranchPerformanceCard({
    super.key,
    required this.branches,
    required this.isBranchManager,
  });

  final List<BranchPerformanceMetric> branches;
  final bool isBranchManager;

  @override
  Widget build(BuildContext context) {
    final isCompact = ContentWidthScope.of(context) < AppBreakpoints.mediumMin;
    return ReportSectionCard(
      icon: Icons.storefront_outlined,
      title: isBranchManager
          ? 'Branch Operational Breakdown'
          : 'Branch Workforce Compliance',
      subtitle: isBranchManager
          ? 'Attendance metrics and exceptions for this location'
          : 'Operational status and attendance rates across assigned branches',
      child: Column(
        children: [
          if (branches.isEmpty)
            Text(
              'No branch figures are available.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            for (final branch in branches)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: isCompact
                    ? _CompactBranch(branch: branch)
                    : _WideBranch(branch: branch),
              ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
        Text(
          value,
          style: AppTypography.labelMono.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BranchTitle extends StatelessWidget {
  const _BranchTitle({required this.branch});

  final BranchPerformanceMetric branch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          branch.branchName,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          branch.headcountLabel,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CompactBranch extends StatelessWidget {
  const _CompactBranch({required this.branch});

  final BranchPerformanceMetric branch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _BranchTitle(branch: branch)),
            const SizedBox(width: AppSpacing.sm),
            StatusChip(
              label: branch.statusLabel,
              type: branch.statusType,
              width: 96,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.xs,
          children: [
            _Metric(
              label: 'Attendance',
              value: ReportFormat.percent(branch.attendanceRate),
              color: AppColors.statusActiveText,
            ),
            _Metric(
              label: 'Exceptions',
              value: branch.exceptionsLabel,
              color: branch.hasPendingExceptions
                  ? AppColors.statusUrgentText
                  : AppColors.onSurface,
            ),
          ],
        ),
      ],
    );
  }
}

class _WideBranch extends StatelessWidget {
  const _WideBranch({required this.branch});

  final BranchPerformanceMetric branch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 4, child: _BranchTitle(branch: branch)),
        Expanded(
          flex: 3,
          child: _Metric(
            label: 'Attendance',
            value: ReportFormat.percent(branch.attendanceRate),
            color: AppColors.statusActiveText,
          ),
        ),
        Expanded(
          flex: 3,
          child: _Metric(
            label: 'Exceptions',
            value: branch.exceptionsLabel,
            color: branch.hasPendingExceptions
                ? AppColors.statusUrgentText
                : AppColors.onSurface,
          ),
        ),
        StatusChip(
          label: branch.statusLabel,
          type: branch.statusType,
          width: 96,
        ),
      ],
    );
  }
}
