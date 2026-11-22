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
import 'package:workaxis/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

class PayslipsScreen extends StatefulWidget {
  const PayslipsScreen({super.key});

  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

enum _PayslipTab { mine, employee, summary }

class _PayslipsScreenState extends State<PayslipsScreen> {
  final _exports = const PayrollExportService();
  late DateTime _month;
  _PayslipTab _tab = _PayslipTab.mine;
  String? _selectedEmployeeId;
  List<OrganizationMember> _members = const [];
  bool _loadingMembers = false;
  String? _membersError;

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
    final activeBranchId = context
        .read<BranchContextController>()
        .activeBranch
        ?.branchId;
    if (_tab == _PayslipTab.employee && _selectedEmployeeId == null) {
      context.read<PayslipsController>().reset();
      return;
    }
    final view = switch (_tab) {
      _PayslipTab.mine => PayrollView.self,
      _PayslipTab.employee => PayrollView.employee,
      _PayslipTab.summary =>
        access.user.role == UserRole.branchManager
            ? PayrollView.branchSummary
            : PayrollView.organizationSummary,
    };
    await context.read<PayslipsController>().load(
      access: access,
      month: _monthKey,
      activeBranchId: activeBranchId,
      view: view,
      selectedMemberId: _selectedEmployeeId,
    );
  }

  Future<void> _loadMembers() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    setState(() {
      _loadingMembers = true;
      _membersError = null;
    });
    try {
      final activeBranchId = context
          .read<BranchContextController>()
          .activeBranch
          ?.branchId;
      final members = await context
          .read<OrganizationMembersRepository>()
          .getMembers(
            access: access,
            activeBranchId: access.user.role == UserRole.branchManager
                ? activeBranchId
                : null,
            maxItems: 500,
          );
      if (!mounted) return;
      setState(() {
        _members = members;
        _loadingMembers = false;
        if (_selectedEmployeeId != null &&
            !_employees.any((member) => member.id == _selectedEmployeeId)) {
          _selectedEmployeeId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMembers = false;
        _membersError = 'Employee list could not be loaded. Try again.';
      });
    }
  }

  List<OrganizationMember> get _employees => _members
      .where((member) => member.role == UserRole.employee)
      .toList(growable: false);

  Future<void> _selectTab(_PayslipTab tab) async {
    setState(() {
      _tab = tab;
      _selectedEmployeeId = null;
    });
    context.read<PayslipsController>().reset();
    if (tab == _PayslipTab.employee) {
      await _loadMembers();
    } else {
      await _load();
    }
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
    final role = access?.user.role;
    final hasEmployeeViews =
        role == UserRole.branchManager || role == UserRole.orgAdmin;
    final isSummaryView = _tab == _PayslipTab.summary;
    final total =
        payroll?.summary?.grossPay ??
        payroll?.records
            .where((record) => record.available)
            .fold<double>(0, (sum, record) => sum + record.grossPay) ??
        0;
    final payslipCount =
        payroll?.summary?.employeeCount ??
        payroll?.records.where((record) => record.available).length ??
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
                if (hasEmployeeViews) ...[
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<_PayslipTab>(
                    segments: [
                      const ButtonSegment(
                        value: _PayslipTab.mine,
                        label: Text('My payslips'),
                        icon: Icon(Icons.person_outline),
                      ),
                      const ButtonSegment(
                        value: _PayslipTab.employee,
                        label: Text('Employee payslip'),
                        icon: Icon(Icons.groups_outlined),
                      ),
                      ButtonSegment(
                        value: _PayslipTab.summary,
                        label: Text(
                          role == UserRole.orgAdmin
                              ? 'All branches'
                              : 'Branch summary',
                        ),
                        icon: Icon(Icons.summarize_outlined),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (selection) =>
                        _selectTab(selection.first),
                  ),
                ],
                if (_tab == _PayslipTab.employee) ...[
                  const SizedBox(height: AppSpacing.md),
                  if (_loadingMembers)
                    const LinearProgressIndicator()
                  else if (_membersError != null)
                    _MessagePanel(
                      message: _membersError!,
                      icon: Icons.error_outline,
                      color: AppColors.statusUrgent,
                      onRetry: _loadMembers,
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedEmployeeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select employee',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final employee in _employees)
                          DropdownMenuItem(
                            value: employee.id,
                            child: Text(employee.fullName),
                          ),
                      ],
                      onChanged: (memberId) {
                        setState(() => _selectedEmployeeId = memberId);
                        _load();
                      },
                    ),
                ],
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _MessagePanel(
                    message: controller.errorMessage!,
                    icon: Icons.error_outline,
                    color: AppColors.statusUrgent,
                    onRetry: _load,
                  ),
                ],
                if (controller.isLoading || _loadingMembers) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const Center(child: CircularProgressIndicator()),
                ] else if (_tab == _PayslipTab.employee &&
                    _selectedEmployeeId == null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const _MessagePanel(
                    message: 'Select an employee to view one monthly payslip.',
                    icon: Icons.person_search_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                ] else if (payroll != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _PayrollSummary(
                    totalGross: total,
                    count: payslipCount,
                    basis: payroll.basis,
                    overtimeEnabled: payroll.overtimeEnabled,
                  ),
                  if (isSummaryView) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            role == UserRole.orgAdmin
                                ? 'Organization payroll summary'
                                : 'Current branch payroll summary',
                            style: AppTypography.titleLarge,
                          ),
                        ),
                        AppButton.outlined(
                          text: 'Export summary',
                          iconData: Icons.download_outlined,
                          isFullWidth: false,
                          onPressed: () => _exportSummaryXlsx(payroll),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Employees assigned to multiple branches are allocated evenly across those branches.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (payroll.branchSummaries.isEmpty)
                      const _EmptyPayroll()
                    else
                      for (final branch in payroll.branchSummaries) ...[
                        _BranchPayrollSummaryCard(branch: branch),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                  ] else ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tab == _PayslipTab.employee
                                ? 'Employee payslip'
                                : 'My payslip',
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

  Future<void> _exportSummaryXlsx(MonthlyPayroll payroll) async {
    try {
      await _exports.exportSummaryXlsx(payroll);
      if (mounted) _toast('Payroll summary exported.');
    } catch (_) {
      if (mounted) _toast('The payroll summary export could not be saved.');
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

class _BranchPayrollSummaryCard extends StatelessWidget {
  const _BranchPayrollSummaryCard({required this.branch});

  final BranchPayrollSummary branch;

  @override
  Widget build(BuildContext context) {
    final summary = branch.summary;
    return Container(
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
                child: Text(
                  branch.branchName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _money(summary.grossPay),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              Text('${summary.employeeCount} employees'),
              Text('${summary.payableHours.toStringAsFixed(2)} payable hours'),
              Text(
                '${summary.unpaidLeaveDays.toStringAsFixed(1)} unpaid leave days',
              ),
              Text(
                '${summary.overtimeHours.toStringAsFixed(2)} overtime hours',
              ),
            ],
          ),
        ],
      ),
    );
  }
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
