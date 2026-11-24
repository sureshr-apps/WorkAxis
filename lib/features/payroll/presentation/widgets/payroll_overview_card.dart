import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/payroll/presentation/payroll_overtime_labels.dart';

class PayrollOverviewCard extends StatelessWidget {
  const PayrollOverviewCard({
    super.key,
    required this.totalGross,
    required this.employeeCount,
    required this.basis,
    required this.overtimeEnabled,
    required this.monthLabel,
    required this.payableHours,
    required this.payableWorkdays,
    required this.overtimeHours,
    required this.approvedOvertimeHours,
    required this.overtimePay,
  });

  final double totalGross;
  final int employeeCount;
  final String basis;
  final bool overtimeEnabled;
  final String monthLabel;
  final double payableHours;
  final double payableWorkdays;

  /// Potential overtime (approved or not).
  final double overtimeHours;

  /// The approved part of [overtimeHours]; only this is paid.
  final double approvedOvertimeHours;
  final double overtimePay;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineSubtle),
          borderRadius: AppSpacing.roundedLg,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D191C20),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gross pay',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        monthLabel,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _PolicyBadge(
                  text:
                      '${basis == 'workdays' ? 'Workday-based' : 'Hours-based'} · ${overtimeEnabled ? 'Overtime on' : 'Overtime off'}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _money(totalGross),
              style: AppTypography.titleLarge.copyWith(
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Total gross pay for $employeeCount ${employeeCount == 1 ? 'employee' : 'employees'}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      ResponsiveKpiSection(
        cards: [
          AppKpiCard(
            title: 'Employees',
            value: '$employeeCount',
            icon: Icons.groups_outlined,
            footerText: 'Included in this payroll',
          ),
          AppKpiCard(
            title: basis == 'workdays' ? 'Payable workdays' : 'Payable hours',
            value: basis == 'workdays'
                ? payableWorkdays.toStringAsFixed(1)
                : payableHours.toStringAsFixed(1),
            total: basis == 'workdays' ? 'days' : 'h',
            icon: basis == 'workdays'
                ? Icons.calendar_today_outlined
                : Icons.schedule_outlined,
            footerText: 'For $monthLabel',
          ),
          AppKpiCard(
            title: 'Approved overtime',
            value: overtimeEnabled
                ? approvedOvertimeHours.toStringAsFixed(1)
                : 'Off',
            total: overtimeEnabled ? 'h' : null,
            icon: Icons.more_time_outlined,
            accentColor: overtimeEnabled ? AppColors.statusActive : null,
            footerText: overtimeEnabled
                ? PayrollOvertimeLabels.potentialAndPaid(
                    overtimeHours,
                    _money(overtimePay),
                  )
                : 'Overtime pay disabled',
          ),
        ],
      ),
    ],
  );

  static String _money(double value) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  ).format(value);
}

class _PolicyBadge extends StatelessWidget {
  const _PolicyBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 180),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: AppSpacing.roundedPill,
    ),
    child: Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
