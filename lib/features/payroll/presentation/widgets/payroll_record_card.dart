import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/payroll/domain/models/monthly_payroll.dart';

class PayrollRecordCard extends StatelessWidget {
  const PayrollRecordCard({
    super.key,
    required this.record,
    required this.month,
    required this.basis,
    required this.overtimeEnabled,
    required this.onExportPdf,
  });

  final PayrollRecord record;
  final String month;
  final String basis;
  final bool overtimeEnabled;
  final Future<void> Function(PayrollRecord, String, String, bool) onExportPdf;

  @override
  Widget build(BuildContext context) => Container(
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${record.employeeCode ?? record.role} · ${_monthLabel(month)}',
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
                  record.available ? _money(record.grossPay) : 'Unavailable',
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
        const SizedBox(height: AppSpacing.lg),
        if (!record.available)
          _UnavailableNotice(reason: record.unavailableReason)
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Column(
              children: [
                _PayrollDetailLine(
                  label: basis == 'workdays'
                      ? 'Paid workdays'
                      : 'Payable hours',
                  value: basis == 'workdays'
                      ? '${record.payableWorkdays} / ${record.scheduledWorkdays} days'
                      : '${record.payableHours.toStringAsFixed(2)} / ${record.scheduledHours.toStringAsFixed(2)} h',
                ),
                const Divider(
                  height: AppSpacing.md,
                  color: AppColors.outlineSubtle,
                ),
                _PayrollDetailLine(
                  label: 'Unpaid leave',
                  value:
                      '${record.unpaidLeaveDays} days · ${_money(record.unpaidLeaveImpact)}',
                ),
                if (overtimeEnabled) ...[
                  const Divider(
                    height: AppSpacing.md,
                    color: AppColors.outlineSubtle,
                  ),
                  _PayrollDetailLine(
                    label: 'Overtime',
                    value:
                        '${record.overtimeHours.toStringAsFixed(2)} h · ${_money(record.overtimePay)}',
                    valueColor: AppColors.statusActiveText,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton.outlined(
            text: 'Export PDF',
            iconData: Icons.picture_as_pdf_outlined,
            isFullWidth: false,
            onPressed: () => onExportPdf(record, month, basis, overtimeEnabled),
          ),
        ),
      ],
    ),
  );

  static String _monthLabel(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return value;
    final date = DateTime.tryParse('${parts[0]}-${parts[1]}-01');
    return date == null ? value : DateFormat('MMMM yyyy').format(date);
  }

  static String _money(double value) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  ).format(value);
}

class _PayrollDetailLine extends StatelessWidget {
  const _PayrollDetailLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: AppTypography.bodySmall.copyWith(
            color: valueColor ?? AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.statusPendingContainer,
      borderRadius: AppSpacing.roundedMd,
      border: Border.all(color: AppColors.statusPendingBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.statusPendingText),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            reason ?? 'Schedule or salary history is missing for this period.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}
