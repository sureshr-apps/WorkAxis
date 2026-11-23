import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/form_action_row.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_input.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_policy.dart';
import 'package:workaxis/features/leave_policy/domain/validators/leave_type_validator.dart';
import 'package:workaxis/features/leave_policy/presentation/formatting/leave_days_format.dart';
import 'package:workaxis/features/settings/presentation/widgets/settings_section_card.dart';

/// Add or edit a leave type: name, yearly allowance and carry-forward. The
/// unpaid type shows its name only, since it has no allowance.
class LeaveTypeEditorDialog extends StatefulWidget {
  const LeaveTypeEditorDialog({
    super.key,
    required this.onSave,
    required this.actionErrorMessage,
    this.leaveType,
  });

  /// Type being edited; null to add one.
  final LeaveTypePolicy? leaveType;

  /// Saves the input; returns whether it was saved.
  final Future<bool> Function(LeaveTypeInput input) onSave;

  /// Why the last save failed, read after [onSave] returns false.
  final String? Function() actionErrorMessage;

  static const nameFieldKey = Key('leave-type-name-field');
  static const daysFieldKey = Key('leave-type-days-field');
  static const carryForwardKey = Key('leave-type-carry-forward');

  static Future<void> show(
    BuildContext context, {
    required Future<bool> Function(LeaveTypeInput input) onSave,
    required String? Function() actionErrorMessage,
    LeaveTypePolicy? leaveType,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeaveTypeEditorDialog(
        leaveType: leaveType,
        onSave: onSave,
        actionErrorMessage: actionErrorMessage,
      ),
    );
  }

  @override
  State<LeaveTypeEditorDialog> createState() => _LeaveTypeEditorDialogState();
}

class _LeaveTypeEditorDialogState extends State<LeaveTypeEditorDialog> {
  final _nameController = TextEditingController();
  final _daysController = TextEditingController();
  bool _carryForward = false;
  String? _nameError;
  String? _daysError;
  String? _saveError;
  bool _isSaving = false;

  bool get _isEditing => widget.leaveType != null;

  /// New types are always paid; only the unpaid type lacks an allowance.
  bool get _hasAllowance => widget.leaveType?.hasAllowance ?? true;

  @override
  void initState() {
    super.initState();
    final type = widget.leaveType;
    _nameController.text = type?.name ?? '';
    _daysController.text = type == null
        ? ''
        : LeaveDaysFormat.number(type.yearlyDays);
    _carryForward = type?.carryForward ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final days = _hasAllowance
        ? LeaveTypeValidator.parseDays(_daysController.text)
        : 0.0;
    setState(() {
      _nameError = LeaveTypeValidator.name(_nameController.text);
      _daysError = _hasAllowance ? LeaveTypeValidator.yearlyDays(days) : null;
      _saveError = null;
    });
    if (_nameError != null || _daysError != null) return;

    setState(() => _isSaving = true);
    final saved = await widget.onSave(
      LeaveTypeInput(
        id: widget.leaveType?.id,
        name: _nameController.text.trim(),
        yearlyDays: days!,
        carryForward: _hasAllowance && _carryForward,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSaving = false;
      _saveError =
          widget.actionErrorMessage() ??
          'The leave type could not be saved. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEditing ? 'Edit leave type' : 'Add leave type',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _hasAllowance
                      ? 'Approved leave within the yearly allowance is paid; days beyond it are unpaid.'
                      : 'Unpaid leave has no allowance: every approved day is unpaid. Only its name can be changed.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  key: LeaveTypeEditorDialog.nameFieldKey,
                  controller: _nameController,
                  label: 'Name',
                  hintText: 'For example, Annual leave',
                  maxLength: LeaveTypeValidator.maxNameLength,
                  errorText: _nameError,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _nameError = null),
                ),
                if (_hasAllowance) ..._allowanceFields(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'A new allowance applies from the next month. Earlier months and past payroll are not affected.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SaveError(message: _saveError!),
                ],
                const SizedBox(height: AppSpacing.xl),
                FormActionRow(
                  submitLabel: _isEditing
                      ? 'Save changes'
                      : 'Create leave type',
                  submitIcon: _isEditing ? Icons.save_outlined : Icons.add,
                  isBusy: _isSaving,
                  onCancel: () => Navigator.of(context).pop(),
                  onSubmit: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _allowanceFields() => [
    const SizedBox(height: AppSpacing.md),
    AppTextField(
      key: LeaveTypeEditorDialog.daysFieldKey,
      controller: _daysController,
      label: 'Yearly allowance (days)',
      hintText: 'For example, 12',
      helperText: 'Days per calendar year, pro-rated from the joining month.',
      errorText: _daysError,
      enabled: !_isSaving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() => _daysError = null),
    ),
    const SizedBox(height: AppSpacing.sm),
    SettingsSwitchTile(
      key: LeaveTypeEditorDialog.carryForwardKey,
      value: _carryForward,
      onChanged: _isSaving
          ? null
          : (value) => setState(() => _carryForward = value),
      title: 'Carry unused days into next year',
      subtitle: 'When off, unused days lapse on 31 December.',
    ),
  ];
}

class _SaveError extends StatelessWidget {
  const _SaveError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.statusUrgentContainer,
          borderRadius: AppSpacing.roundedSm,
        ),
        child: Text(
          message,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.statusUrgentText,
          ),
        ),
      ),
    );
  }
}
