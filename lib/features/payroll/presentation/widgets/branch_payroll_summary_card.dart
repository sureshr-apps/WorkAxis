import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/payroll/domain/models/monthly_payroll.dart';

class BranchPayrollSummaryCard extends StatelessWidget {
  const BranchPayrollSummaryCard({
    super.key,
    required this.branch,
    required this.basis,
    required this.overtimeEnabled,
  });

  final BranchPayrollSummary branch;
  final String basis;
  final bool overtimeEnabled;

  @override
  Widget build(BuildContext context) {
    final summary = branch.summary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineSubtle),
        borderRadius: AppSpacing.roundedMd,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D191C20),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${summary.employeeCount} ${summary.employeeCount == 1 ? 'employee' : 'employees'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(summary.grossPay),
                    maxLines: 1,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Gross pay',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.outlineSubtle),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _BranchMetric(
                icon: Icons.schedule_outlined,
                label: basis == 'workdays'
                    ? '${summary.payableWorkdays.toStringAsFixed(1)} payable days'
                    : '${summary.payableHours.toStringAsFixed(1)} payable h',
              ),
              if (summary.unpaidLeaveDays > 0)
                _BranchMetric(
                  icon: Icons.event_busy_outlined,
                  label:
                      '${summary.unpaidLeaveDays.toStringAsFixed(1)} unpaid leave days',
                  color: AppColors.statusPendingText,
                ),
              if (overtimeEnabled)
                _BranchMetric(
                  icon: Icons.more_time_outlined,
                  label:
                      '${summary.overtimeHours.toStringAsFixed(1)} overtime h',
                  color: AppColors.statusActiveText,
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _money(double value) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  ).format(value);
}

class _BranchMetric extends StatelessWidget {
  const _BranchMetric({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color ?? AppColors.onSurfaceVariant),
      const SizedBox(width: AppSpacing.xs),
      Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: color ?? AppColors.onSurfaceVariant,
          fontWeight: color == null ? FontWeight.w500 : FontWeight.w600,
        ),
      ),
    ],
  );
}
