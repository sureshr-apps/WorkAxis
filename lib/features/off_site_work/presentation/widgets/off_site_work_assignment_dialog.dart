import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';

Future<bool?> showOffSiteWorkAssignmentDialog({
  required BuildContext context,
  required UserAccessContext access,
  required String? activeBranchId,
  required OrganizationMembersRepository membersRepository,
  required Future<bool> Function(OffSiteWorkAssignmentDraft draft) onSubmit,
  required String? Function() failureMessage,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => OffSiteWorkAssignmentDialog(
    access: access,
    activeBranchId: activeBranchId,
    membersRepository: membersRepository,
    onSubmit: onSubmit,
    failureMessage: failureMessage,
  ),
);

class OffSiteWorkAssignmentDialog extends StatefulWidget {
  const OffSiteWorkAssignmentDialog({
    super.key,
    required this.access,
    required this.activeBranchId,
    required this.membersRepository,
    required this.onSubmit,
    required this.failureMessage,
  });

  final UserAccessContext access;
  final String? activeBranchId;
  final OrganizationMembersRepository membersRepository;
  final Future<bool> Function(OffSiteWorkAssignmentDraft draft) onSubmit;
  final String? Function() failureMessage;

  @override
  State<OffSiteWorkAssignmentDialog> createState() =>
      _OffSiteWorkAssignmentDialogState();
}

class _OffSiteWorkAssignmentDialogState
    extends State<OffSiteWorkAssignmentDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _destinationController;
  late final TextEditingController _referenceController;
  late final TextEditingController _evidenceController;
  late final bool _branchLocked;
  late final List<BranchSummary> _branches;
  String? _branchId;
  String? _employeeId;
  String? _titleError;
  String? _destinationError;
  String? _employeeError;
  String? _formError;
  DateTime? _dueAt;
  List<OrganizationMember> _employees = const [];
  bool _loadingEmployees = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _instructionsController = TextEditingController();
    _destinationController = TextEditingController();
    _referenceController = TextEditingController();
    _evidenceController = TextEditingController();
    _branchLocked = widget.access.user.role == UserRole.branchManager;
    _branches = widget.access.activeAssignedBranches;
    _branchId = _branchLocked
        ? widget.activeBranchId
        : widget.access.activeBranch?.branchId ?? _branches.firstOrNull?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEmployees());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _destinationController.dispose();
    _referenceController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    final branchId = _branchId;
    if (branchId == null) {
      setState(() {
        _employees = const [];
        _employeeId = null;
        _loadingEmployees = false;
      });
      return;
    }
    setState(() {
      _loadingEmployees = true;
      _employees = const [];
      _employeeId = null;
      _employeeError = null;
    });
    try {
      final employees = <OrganizationMember>[];
      var offset = 0;
      while (employees.length < 1000) {
        final page = await widget.membersRepository.getMembersPage(
          access: widget.access,
          activeBranchId: _branchLocked ? branchId : null,
          role: UserRole.employee,
          status: AccountStatus.active,
          offset: offset,
          limit: 100,
        );
        employees.addAll(page.items);
        if (!page.hasMore) break;
        offset = page.nextOffset;
      }
      if (!mounted) return;
      setState(() {
        _employees = employees
            .where(
              (employee) =>
                  employee.branchIds.contains(branchId) &&
                  employee.authUid != null,
            )
            .toList(growable: false);
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _formError = 'Employee list could not be loaded. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  Future<void> _selectDueAt() async {
    final now = DateTime.now();
    final initial = _dueAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return;
    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final destination = _destinationController.text.trim();
    setState(() {
      _titleError = title.isEmpty
          ? 'Enter a title.'
          : title.length > 120
          ? 'Use 120 characters or fewer.'
          : null;
      _destinationError = destination.isEmpty
          ? 'Enter a destination.'
          : destination.length > 250
          ? 'Use 250 characters or fewer.'
          : null;
      _employeeError = _employeeId == null ? 'Choose an employee.' : null;
      _formError = null;
    });
    return _branchId != null &&
        _titleError == null &&
        _destinationError == null &&
        _employeeError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final branchId = _branchId;
    final employeeId = _employeeId;
    if (branchId == null || employeeId == null) return;
    setState(() => _isSaving = true);
    final saved = await widget.onSubmit(
      OffSiteWorkAssignmentDraft(
        branchId: branchId,
        employeeMemberId: employeeId,
        title: _titleController.text.trim(),
        destination: _destinationController.text.trim(),
        instructions: _instructionsController.text,
        dueAt: _dueAt,
        reference: _referenceController.text,
        requiredEvidenceDescription: _evidenceController.text,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSaving = false;
        _formError =
            widget.failureMessage() ??
            'Assignment could not be saved. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign off-site work'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'The employee records start, arrival, outcome, and return. Each step stores one location and does not change attendance.',
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_branchLocked)
                _LockedBranchLabel(
                  branch: _branches
                      .where((branch) => branch.id == _branchId)
                      .firstOrNull,
                )
              else
                DropdownButtonFormField<String>(
                  initialValue:
                      _branches.any((branch) => branch.id == _branchId)
                      ? _branchId
                      : null,
                  decoration: const InputDecoration(labelText: 'Branch'),
                  items: [
                    for (final branch in _branches)
                      DropdownMenuItem(
                        value: branch.id,
                        child: Text('${branch.name} · ${branch.code}'),
                      ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (id) {
                          setState(() => _branchId = id);
                          _loadEmployees();
                        },
                ),
              const SizedBox(height: AppSpacing.md),
              if (_employees.isEmpty && !_loadingEmployees)
                const Text(
                  'No active employees with sign-in access are assigned to this branch.',
                ),
              DropdownButtonFormField<String>(
                initialValue:
                    _employees.any((employee) => employee.id == _employeeId)
                    ? _employeeId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Employee',
                  helperText: _loadingEmployees ? 'Loading employees…' : null,
                  errorText: _employeeError,
                ),
                items: [
                  for (final employee in _employees)
                    DropdownMenuItem(
                      value: employee.id,
                      child: Text(employee.fullName),
                    ),
                ],
                onChanged: _isSaving || _loadingEmployees
                    ? null
                    : (id) => setState(() => _employeeId = id),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hintText: 'e.g. Deposit cash at the bank',
                maxLength: 120,
                errorText: _titleError,
                enabled: !_isSaving,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _destinationController,
                label: 'Destination',
                hintText: 'Address or place name',
                maxLength: 250,
                errorText: _destinationError,
                enabled: !_isSaving,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _instructionsController,
                label: 'Instructions',
                hintText: 'What should the employee do?',
                minLines: 2,
                maxLines: 4,
                maxLength: 4000,
                enabled: !_isSaving,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _selectDueAt,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(
                  _dueAt == null
                      ? 'Add due time (optional)'
                      : AppFormatters.formatDateTime(_dueAt),
                ),
              ),
              if (_dueAt != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _dueAt = null),
                    child: const Text('Clear due time'),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _referenceController,
                label: 'Reference (optional)',
                hintText: 'Order, account, or internal reference',
                maxLength: 200,
                enabled: !_isSaving,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _evidenceController,
                label: 'Completion evidence (optional)',
                hintText: 'e.g. Deposit slip, recipient OTP, or receipt',
                helperText: 'When set, the employee must add a note or photo before completing.',
                maxLength: 500,
                enabled: !_isSaving,
              ),
              if (_formError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _formError!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppButton.outlined(
          text: 'Cancel',
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          isFullWidth: false,
        ),
        AppButton.primary(
          text: 'Assign',
          iconData: Icons.send_outlined,
          isLoading: _isSaving,
          onPressed: _isSaving || _loadingEmployees || _branches.isEmpty
              ? null
              : _save,
          isFullWidth: false,
        ),
      ],
    );
  }
}

class _LockedBranchLabel extends StatelessWidget {
  const _LockedBranchLabel({required this.branch});

  final BranchSummary? branch;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Active branch'),
      child: Text(
        branch == null ? 'Select an active branch first' : branch!.name,
      ),
    );
  }
}
