import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
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
import 'package:workaxis/features/payroll/presentation/widgets/branch_payroll_summary_card.dart';
import 'package:workaxis/features/payroll/presentation/widgets/payroll_overview_card.dart';
import 'package:workaxis/features/payroll/presentation/widgets/payroll_record_card.dart';
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
    final availableRecords =
        payroll?.records.where((record) => record.available).toList() ??
        const <PayrollRecord>[];
    final total =
        payroll?.summary?.grossPay ??
        payroll?.records
            .where((record) => record.available)
            .fold<double>(0, (sum, record) => sum + record.grossPay) ??
        0;
    final payslipCount =
        payroll?.summary?.availableCount ??
        payroll?.records.where((record) => record.available).length ??
        0;
    final payableHours =
        payroll?.summary?.payableHours ??
        availableRecords.fold<double>(
          0,
          (sum, record) => sum + record.payableHours,
        );
    final payableWorkdays =
        payroll?.summary?.payableWorkdays ??
        availableRecords.fold<double>(
          0,
          (sum, record) => sum + record.payableWorkdays,
        );
    final overtimeHours =
        payroll?.summary?.overtimeHours ??
        availableRecords.fold<double>(
          0,
          (sum, record) => sum + record.overtimeHours,
        );
    final approvedOvertimeHours =
        payroll?.summary?.approvedOvertimeHours ??
        availableRecords.fold<double>(
          0,
          (sum, record) => sum + record.approvedOvertimeHours,
        );
    final overtimePay =
        payroll?.summary?.overtimePay ??
        availableRecords.fold<double>(
          0,
          (sum, record) => sum + record.overtimePay,
        );

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
                  subtitle: 'Review monthly pay and download payslips.',
                ),
                const SizedBox(height: AppSpacing.lg),
                _monthControls(controller),
                if (hasEmployeeViews) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppSpacing.roundedMd,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<_PayslipTab>(
                        showSelectedIcon: false,
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
                    ),
                  ),
                ],
                if (_tab == _PayslipTab.employee) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
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
                            const Icon(
                              Icons.person_search_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Choose an employee',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
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
                              hintText: 'Select employee',
                              prefixIcon: Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.surface,
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
                    ),
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
                  PayrollOverviewCard(
                    totalGross: total,
                    employeeCount: payslipCount,
                    basis: payroll.basis,
                    overtimeEnabled: payroll.overtimeEnabled,
                    monthLabel: DateFormat('MMMM yyyy').format(_month),
                    payableHours: payableHours,
                    payableWorkdays: payableWorkdays,
                    overtimeHours: overtimeHours,
                    approvedOvertimeHours: approvedOvertimeHours,
                    overtimePay: overtimePay,
                  ),
                  if (isSummaryView) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Branch breakdown',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                role == UserRole.orgAdmin
                                    ? '${payroll.branchSummaries.length} branches in this organization'
                                    : 'For your active branch',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppButton.outlined(
                          text: 'Export XLSX',
                          iconData: Icons.download_outlined,
                          isFullWidth: false,
                          onPressed: () => _exportSummaryXlsx(payroll),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (payroll.branchSummaries.isEmpty)
                      const _EmptyPayroll()
                    else
                      for (final branch in payroll.branchSummaries) ...[
                        BranchPayrollSummaryCard(
                          branch: branch,
                          basis: payroll.basis,
                          overtimeEnabled: payroll.overtimeEnabled,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    if (payroll.branchSummaries.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppSpacing.roundedMd,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Employees assigned to multiple branches are allocated evenly across branch summaries.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      for (final record in payroll.records) ...[
                        PayrollRecordCard(
                          record: record,
                          month: payroll.month,
                          basis: payroll.basis,
                          overtimeEnabled: payroll.overtimeEnabled,
                          onExportPdf: _exportPdf,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
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

  Widget _monthControls(PayslipsController controller) {
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
