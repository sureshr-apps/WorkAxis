import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

class LeaveRequestFormResult {
  const LeaveRequestFormResult({required this.branchId, required this.draft});

  final String branchId;
  final LeaveRequestDraft draft;
}

Future<bool> showLeaveRequestFormDialog({
  required BuildContext context,
  required List<BranchSummary> branches,
  required String? initialBranchId,
  required bool branchLocked,
  required Future<bool> Function(LeaveRequestFormResult result) onSubmit,
  String? Function()? failureMessage,
  LeaveRequest? request,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LeaveRequestFormDialog(
        branches: branches,
        initialBranchId: initialBranchId,
        branchLocked: branchLocked,
        onSubmit: onSubmit,
        failureMessage: failureMessage,
        request: request,
      ),
    ) ??
    false;

class LeaveRequestFormDialog extends StatefulWidget {
  const LeaveRequestFormDialog({
    super.key,
    required this.branches,
    required this.initialBranchId,
    required this.branchLocked,
    required this.onSubmit,
    required this.failureMessage,
    this.request,
  });

  final List<BranchSummary> branches;
  final String? initialBranchId;
  final bool branchLocked;
  final Future<bool> Function(LeaveRequestFormResult result) onSubmit;
  final String? Function()? failureMessage;
  final LeaveRequest? request;

  @override
  State<LeaveRequestFormDialog> createState() => _LeaveRequestFormDialogState();
}

class _LeaveRequestFormDialogState extends State<LeaveRequestFormDialog> {
  final _reasonController = TextEditingController();
  LeaveType _leaveType = LeaveType.annual;
  DateTime? _startDate;
  DateTime? _endDate;
  BranchSummary? _branch;
  String? _reasonError;
  String? _actionError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final request = widget.request;
    _leaveType = request?.leaveType ?? LeaveType.annual;
    _startDate = request?.startDate ?? _calendarDay(DateTime.now());
    _endDate = request?.endDate ?? _startDate;
    _reasonController.text = request?.reason ?? '';
    _branch = widget.branches
        .where(
          (branch) =>
              branch.id == (request?.branchId ?? widget.initialBranchId),
        )
        .firstOrNull;
    _reasonController.addListener(_onReasonChanged);
  }

  @override
  void dispose() {
    _reasonController
      ..removeListener(_onReasonChanged)
      ..dispose();
    super.dispose();
  }

  void _onReasonChanged() {
    if (_reasonError != null && _reasonController.text.trim().isNotEmpty) {
      setState(() => _reasonError = null);
    }
  }

  DateTime _calendarDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _chooseDate({required bool start}) async {
    final current = start ? _startDate! : _endDate!;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (start) {
        _startDate = _calendarDay(picked);
        if (_endDate!.isBefore(_startDate!)) _endDate = _startDate;
      } else {
        _endDate = _calendarDay(picked);
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _reasonError = 'Enter a reason for your leave.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      return;
    }
    final branch = _branch;
    if (branch == null) return;
    final result = LeaveRequestFormResult(
      branchId: branch.id,
      draft: LeaveRequestDraft(
        leaveType: _leaveType,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: reason,
      ),
    );
    setState(() {
      _isSaving = true;
      _actionError = null;
    });
    var saved = false;
    try {
      saved = await widget.onSubmit(result);
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    final suppliedMessage = widget.failureMessage?.call()?.trim();
    setState(() {
      _isSaving = false;
      _actionError = suppliedMessage == null || suppliedMessage.isEmpty
          ? 'The leave request could not be saved. Try again.'
          : suppliedMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.request != null;
    final branchOptions = widget.branches
        .where((branch) => branch.isActive)
        .toList(growable: false);
    final dateError = _endDate!.isBefore(_startDate!)
        ? 'End date must be on or after the start date.'
        : null;

    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
        title: Text(editing ? 'Edit leave request' : 'Apply for leave'),
        content: SizedBox(
          width: 520,
          child: AbsorbPointer(
            absorbing: _isSaving,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (branchOptions.length > 1 && !widget.branchLocked)
                    DropdownButtonFormField<BranchSummary>(
                      initialValue: _branch,
                      decoration: const InputDecoration(
                        labelText: 'Branch',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final branch in branchOptions)
                          DropdownMenuItem(
                            value: branch,
                            child: Text(
                              branch.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (branch) => setState(() => _branch = branch),
                    )
                  else if (_branch != null)
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Branch',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_branch!.name),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<LeaveType>(
                    initialValue: _leaveType,
                    decoration: const InputDecoration(
                      labelText: 'Leave type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final type in LeaveType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: (type) {
                      if (type != null) setState(() => _leaveType = type);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DatePickerField(
                    label: 'Start date',
                    value: MaterialLocalizations.of(context)
                        .formatMediumDate(_startDate!),
                    onTap: () => _chooseDate(start: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DatePickerField(
                    label: 'End date',
                    value: MaterialLocalizations.of(context)
                        .formatMediumDate(_endDate!),
                    errorText: dateError,
                    onTap: () => _chooseDate(start: false),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _reasonController,
                    label: 'Reason',
                    hintText: 'Add a short reason for your request',
                    maxLines: 3,
                    maxLength: 2000,
                    errorText: _reasonError,
                  ),
                  if (editing &&
                      widget.request!.status == LeaveStatus.pending) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Text('Only pending requests can be edited.'),
                  ],
                  if (_actionError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _actionError!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.statusUrgentText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          AppButton.outlined(
            text: 'Cancel',
            isFullWidth: false,
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).pop(false),
          ),
          AppButton.primary(
            text: editing ? 'Save changes' : 'Submit request',
            isFullWidth: false,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label: $value',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value),
      ),
    ),
  );
}
