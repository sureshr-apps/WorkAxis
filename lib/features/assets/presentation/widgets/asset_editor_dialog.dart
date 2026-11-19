import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

class AssetEditorDialog extends StatefulWidget {
  const AssetEditorDialog({
    super.key,
    required this.organizationId,
    required this.branches,
    required this.employees,
    required this.onSave,
    required this.actionErrorMessage,
    this.asset,
    this.fixedBranchId,
  });

  final String organizationId;
  final List<BranchSummary> branches;
  final List<OrganizationMember> employees;
  final EmployeeAsset? asset;
  final String? fixedBranchId;
  final Future<bool> Function(EmployeeAsset asset) onSave;
  final String? Function() actionErrorMessage;

  @override
  State<AssetEditorDialog> createState() => _AssetEditorDialogState();
}

class _AssetEditorDialogState extends State<AssetEditorDialog> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagController = TextEditingController();
  final _serialController = TextEditingController();
  final _notesController = TextEditingController();

  late String? _branchId;
  String? _employeeId;
  late AssetStatus _status;
  String? _branchError;
  String? _employeeError;
  String? _nameError;
  String? _categoryError;
  String? _tagError;
  String? _saveError;
  bool _isSaving = false;

  bool get _isEditing => widget.asset != null;
  String get _branchName {
    final matches = _availableBranches.where(
      (branch) => branch.id == _branchId,
    );
    return matches.isEmpty ? 'Active outlet' : matches.first.name;
  }

  List<BranchSummary> get _availableBranches => widget.fixedBranchId == null
      ? widget.branches
      : widget.branches
            .where((branch) => branch.id == widget.fixedBranchId)
            .toList(growable: false);

  List<OrganizationMember> get _employeesForBranch => widget.employees
      .where((employee) => employee.branchIds.contains(_branchId))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    _nameController.text = asset?.name ?? '';
    _categoryController.text = asset?.category ?? '';
    _tagController.text = asset?.assetTag ?? '';
    _serialController.text = asset?.serialNumber ?? '';
    _notesController.text = asset?.notes ?? '';
    if (widget.fixedBranchId != null) {
      _branchId = widget.fixedBranchId;
    } else {
      final currentBranch = _availableBranches.where(
        (branch) => branch.id == asset?.branchId,
      );
      _branchId = currentBranch.isNotEmpty
          ? currentBranch.first.id
          : (_availableBranches.isEmpty ? null : _availableBranches.first.id);
    }
    _employeeId = asset?.employeeId;
    _status = asset?.status ?? AssetStatus.assigned;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    _serialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = _employeesForBranch;
    if (_employeeId == null ||
        !employees.any((employee) => employee.id == _employeeId)) {
      _employeeId = employees.isEmpty ? null : employees.first.id;
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing ? 'Edit asset' : 'Add asset',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Assign an organization asset to an employee at an outlet.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _nameController,
                label: 'Asset name',
                hintText: 'For example, Work laptop',
                maxLength: 120,
                errorText: _nameError,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() => _nameError = null),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _categoryController,
                label: 'Category',
                hintText: 'For example, Computer',
                maxLength: 80,
                errorText: _categoryError,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _categoryError = null),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _tagController,
                label: 'Asset tag',
                hintText: 'Unique tag used by your organization',
                maxLength: 80,
                errorText: _tagError,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _tagError = null),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _serialController,
                label: 'Serial number (optional)',
                hintText: 'Enter the manufacturer serial number',
                maxLength: 128,
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.fixedBranchId == null)
                DropdownButtonFormField<String>(
                  key: ValueKey(_branchId),
                  initialValue: _branchId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Outlet',
                    errorText: _branchError,
                  ),
                  items: [
                    for (final branch in _availableBranches)
                      DropdownMenuItem(
                        value: branch.id,
                        child: Text(branch.name),
                      ),
                  ],
                  onChanged: _availableBranches.isEmpty
                      ? null
                      : (value) => setState(() {
                          _branchId = value;
                          _employeeId = null;
                          _branchError = null;
                          _employeeError = null;
                        }),
                )
              else
                _FixedScopeField(label: 'Outlet', value: _branchName),
              if (_branchId == null && _branchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    _branchError!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: ValueKey(_branchId),
                initialValue: _employeeId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Employee',
                  errorText: _employeeError,
                ),
                items: [
                  for (final employee in employees)
                    DropdownMenuItem(
                      value: employee.id,
                      child: Text(employee.fullName),
                    ),
                ],
                onChanged: employees.isEmpty
                    ? null
                    : (value) => setState(() {
                        _employeeId = value;
                        _employeeError = null;
                      }),
                hint: Text(
                  employees.isEmpty
                      ? 'No employees assigned to this outlet'
                      : 'Select an employee',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<AssetStatus>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final status in AssetStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _notesController,
                label: 'Notes (optional)',
                hintText: 'Add useful handover or condition details',
                minLines: 2,
                maxLines: 4,
                maxLength: 2000,
              ),
              if (_saveError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.statusUrgentContainer,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Text(
                    _saveError!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.statusUrgentText,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton.outlined(
                    text: 'Cancel',
                    isFullWidth: false,
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  AppButton.primary(
                    text: _isEditing ? 'Save changes' : 'Add asset',
                    iconData: _isEditing ? Icons.save_outlined : Icons.add,
                    isFullWidth: false,
                    isLoading: _isSaving,
                    onPressed: _isSaving || employees.isEmpty ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final assetTag = _tagController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Enter an asset name.' : null;
      _categoryError = category.isEmpty ? 'Enter a category.' : null;
      _tagError = assetTag.isEmpty ? 'Enter an asset tag.' : null;
      _branchError = _branchId == null ? 'Select an outlet.' : null;
      _employeeError = _employeeId == null ? 'Select an employee.' : null;
      _saveError = null;
    });
    if (_nameError != null ||
        _categoryError != null ||
        _tagError != null ||
        _branchError != null ||
        _employeeError != null) {
      return;
    }

    final branches = _availableBranches.where((item) => item.id == _branchId);
    final branch = branches.isEmpty ? null : branches.first;
    final employeeMatches = _employeesForBranch.where(
      (item) => item.id == _employeeId,
    );
    final employee = employeeMatches.isEmpty ? null : employeeMatches.first;
    if (employee == null) {
      setState(() => _employeeError = 'Choose an employee at this outlet.');
      return;
    }

    setState(() => _isSaving = true);
    final saved = await widget.onSave(
      EmployeeAsset(
        id: widget.asset?.id ?? '',
        organizationId: widget.organizationId,
        branchId: _branchId!,
        branchName: branch?.name ?? widget.asset?.branchName ?? '',
        employeeId: employee.id,
        employeeName: employee.fullName,
        name: name,
        category: category,
        assetTag: assetTag,
        status: _status,
        serialNumber: _serialController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _saveError = saved
          ? null
          : widget.actionErrorMessage() ??
                'The asset could not be saved. Please try again.';
    });
    if (saved) Navigator.of(context).pop();
  }
}

class _FixedScopeField extends StatelessWidget {
  const _FixedScopeField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: Text(value, style: AppTypography.bodyMedium),
  );
}
