import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/core/responsive/responsive_page_content.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/payroll/data/payroll_export_service.dart';
import 'package:workaxis/features/payroll/domain/models/monthly_payroll.dart';
import 'package:workaxis/features/payroll/presentation/controllers/payslips_controller.dart';

class PayslipsScreen extends StatefulWidget {
  const PayslipsScreen({super.key});

  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  final _exports = const PayrollExportService();
  late DateTime _month;

  String get _monthKey => DateFormat('yyyy-MM').format(_month);

  @override
  void initState() {
    super.initState();
    _month = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    await context.read<PayslipsController>().load(
      access: access,
      month: _monthKey,
      activeBranchId: context
          .read<BranchContextController>()
          .activeBranch
          ?.branchId,
    );
  }

  void _moveMonth(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months, 1));
    _load();
  }

  Future<void> _chooseMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 366 * 2)),
      helpText: 'SELECT A DATE IN THE PAY PERIOD',
    );
    if (picked == null || !mounted) return;
    setState(() => _month = picked);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessController>().accessContext;
    final controller = context.watch<PayslipsController>();
    final payroll = controller.payroll;
    final total =
        payroll?.records
            .where((record) => record.available)
            .fold<double>(0, (sum, record) => sum + record.grossPay) ??
        0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageBreadcrumb(
                  backLabel: 'Home',
                  currentLabel: 'Payslips',
                  onBack: () => context.go(_homeRoute(access?.user.role)),
                ),
                const SizedBox(height: AppSpacing.md),
                const AppPageHeader(
                  eyebrow: 'Payroll',
                  title: 'Payslips',
                  subtitle: 'Review gross monthly pay, attendance hours, unpaid leave, and overtime.',
                ),
                const SizedBox(height: AppSpacing.lg),
                _monthControls(controller, payroll),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _MessagePanel(
                    message: controller.errorMessage!,
                    icon: Icons.error_outline,
                    color: AppColors.statusUrgent,
                    onRetry: _load,
                  ),
                ],
                if (controller.isLoading) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const Center(child: CircularProgressIndicator()),
                ] else if (payroll != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _PayrollSummary(
                    totalGross: total,
                    count: payroll.records
                        .where((record) => record.available)
                        .length,
                    basis: payroll.basis,
                    overtimeEnabled: payroll.overtimeEnabled,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Monthly records',
                          style: AppTypography.titleLarge,
                        ),
                      ),
                      AppButton.outlined(
                        text: 'Export XLSX',
                        iconData: Icons.download_outlined,
                        isFullWidth: false,
                        onPressed: payroll.records.isEmpty
                            ? null
                            : () => _exportXlsx(payroll),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (payroll.records.isEmpty)
                    const _EmptyPayroll()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) =>
                          constraints.maxWidth >= AppBreakpoints.wideContent
                          ? _PayrollTable(
                              records: payroll.records,
                              month: payroll.month,
                              basis: payroll.basis,
                              overtimeEnabled: payroll.overtimeEnabled,
                              onExportPdf: _exportPdf,
                            )
                          : _PayrollCards(
                              records: payroll.records,
                              month: payroll.month,
                              basis: payroll.basis,
                              overtimeEnabled: payroll.overtimeEnabled,
                              onExportPdf: _exportPdf,
                            ),
                    ),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthControls(
    PayslipsController controller,
    MonthlyPayroll? payroll,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineSubtle),
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: controller.isLoading ? null : () => _moveMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: controller.isLoading ? null : _chooseMonth,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                DateFormat('MMMM yyyy').format(_month),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: controller.isLoading ? null : () => _moveMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Future<void> _exportXlsx(MonthlyPayroll payroll) async {
    try {
      await _exports.exportMonthlyXlsx(payroll);
      if (mounted) _toast('Monthly XLSX exported.');
    } catch (_) {
      if (mounted) _toast('The XLSX export could not be saved.');
    }
  }

  Future<void> _exportPdf(
    PayrollRecord record,
    String month,
    String basis,
    bool overtimeEnabled,
  ) async {
    try {
      await _exports.exportIndividualPdf(
        record: record,
        month: month,
        payBasis: basis,
        overtimeEnabled: overtimeEnabled,
      );
      if (mounted) _toast('Payslip PDF exported.');
    } catch (_) {
      if (mounted) _toast('The payslip PDF could not be saved.');
    }
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  String _homeRoute(UserRole? role) => switch (role) {
    UserRole.orgAdmin => AppRoutes.orgAdminWorkspace,
    UserRole.branchManager => AppRoutes.branchManagerWorkspace,
    _ => AppRoutes.employeeWorkspace,
  };
}

class _PayrollSummary extends StatelessWidget {
  const _PayrollSummary({
    required this.totalGross,
    required this.count,
    required this.basis,
    required this.overtimeEnabled,
  });

  final double totalGross;
  final int count;
  final String basis;
  final bool overtimeEnabled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: AppSpacing.roundedMd,
    ),
    child: Wrap(
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.spaceBetween,
      children: [
        _Metric(label: 'Gross pay', value: _money(totalGross)),
        _Metric(label: 'Payslips ready', value: '$count'),
        _Metric(
          label: 'Pay basis',
          value: basis == 'workdays' ? 'Workdays' : 'Hours',
        ),
        _Metric(label: 'Overtime', value: overtimeEnabled ? 'Enabled' : 'Off'),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        value,
        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _PayrollTable extends StatelessWidget {
  const _PayrollTable({
    required this.records,
    required this.month,
    required this.basis,
    required this.overtimeEnabled,
    required this.onExportPdf,
  });
  final List<PayrollRecord> records;
  final String month;
  final String basis;
  final bool overtimeEnabled;
  final Future<void> Function(PayrollRecord, String, String, bool) onExportPdf;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Employee')),
        DataColumn(label: Text('Payable')),
        DataColumn(label: Text('Unpaid leave')),
        DataColumn(label: Text('Overtime')),
        DataColumn(label: Text('Gross pay'), numeric: true),
        DataColumn(label: Text('Payslip')),
      ],
      rows: records
          .map(
            (record) => DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        record.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        record.employeeCode ?? record.role,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    record.available
                        ? basis == 'workdays'
                              ? '${record.payableWorkdays} days'
                              : '${record.payableHours.toStringAsFixed(2)} h'
                        : '—',
                  ),
                ),
                DataCell(
                  Text(
                    record.available ? '${record.unpaidLeaveDays} days' : '—',
                  ),
                ),
                DataCell(
                  Text(
                    record.available
                        ? '${record.overtimeHours.toStringAsFixed(2)} h · ${_money(record.overtimePay)}'
                        : '—',
                  ),
                ),
                DataCell(
                  Text(
                    record.available ? _money(record.grossPay) : 'Unavailable',
                  ),
                ),
                DataCell(
                  AppButton.outlined(
                    text: 'PDF',
                    iconData: Icons.picture_as_pdf_outlined,
                    isFullWidth: false,
                    onPressed: () =>
                        onExportPdf(record, month, basis, overtimeEnabled),
                  ),
                ),
              ],
            ),
          )
          .toList(growable: false),
    ),
  );
}

class _PayrollCards extends StatelessWidget {
  const _PayrollCards({
    required this.records,
    required this.month,
    required this.basis,
    required this.overtimeEnabled,
    required this.onExportPdf,
  });
  final List<PayrollRecord> records;
  final String month;
  final String basis;
  final bool overtimeEnabled;
  final Future<void> Function(PayrollRecord, String, String, bool) onExportPdf;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final record in records) ...[
        _PayrollRecordCard(
          record: record,
          month: month,
          basis: basis,
          overtimeEnabled: overtimeEnabled,
          onExportPdf: onExportPdf,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ],
  );
}

class _PayrollRecordCard extends StatelessWidget {
  const _PayrollRecordCard({
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
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: AppSpacing.roundedMd,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.fullName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    record.employeeCode ?? record.role,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              record.available ? _money(record.grossPay) : 'Unavailable',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (!record.available)
          Text(
            'Schedule or salary history is missing for this period.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          )
        else ...[
          _DetailLine(
            label: basis == 'workdays' ? 'Paid workdays' : 'Payable hours',
            value: basis == 'workdays'
                ? '${record.payableWorkdays} / ${record.scheduledWorkdays}'
                : '${record.payableHours.toStringAsFixed(2)} / ${record.scheduledHours.toStringAsFixed(2)} h',
          ),
          _DetailLine(
            label: 'Unpaid leave',
            value:
                '${record.unpaidLeaveDays} days · ${_money(record.unpaidLeaveImpact)}',
          ),
          _DetailLine(
            label: 'Overtime',
            value:
                '${record.overtimeHours.toStringAsFixed(2)} h · ${_money(record.overtimePay)}',
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
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
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _EmptyPayroll extends StatelessWidget {
  const _EmptyPayroll();
  @override
  Widget build(BuildContext context) => const _MessagePanel(
    message:
        'No payslip records are available for this month and access scope.',
    icon: Icons.receipt_long_outlined,
    color: AppColors.onSurfaceVariant,
  );
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.message,
    required this.icon,
    required this.color,
    this.onRetry,
  });
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: AppSpacing.roundedMd,
    ),
    child: Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(message, style: AppTypography.bodyMedium)),
            ],
          ),
        ),
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
      ],
    ),
  );
}

String _money(double value) => NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
).format(value);
