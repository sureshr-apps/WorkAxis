import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_form_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Branch, shift, time, status and note inputs of the group check-in dialog.
class GroupAttendanceConfigSection extends StatelessWidget {
  const GroupAttendanceConfigSection({
    super.key,
    required this.form,
    required this.access,
    required this.onPickTime,
  });

  final GroupAttendanceFormController form;
  final UserAccessContext access;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final canChangeBranch =
        access.user.role == UserRole.orgAdmin &&
        access.assignedBranches.length > 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canChangeBranch) ...[
            const _FieldLabel('Branch Location'),
            DropdownButtonFormField<String>(
              initialValue: form.branchId,
              isExpanded: true,
              decoration: _decoration(),
              items: [
                for (final b in access.assignedBranches)
                  DropdownMenuItem(value: b.id, child: Text(b.name)),
              ],
              onChanged: (id) {
                if (id != null) form.selectBranch(id);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const _FieldLabel('Shift'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final shift in GroupAttendanceFormController.shifts)
                _ShiftChip(
                  label: shift,
                  selected: form.shift == shift,
                  onSelected: () => form.setShift(shift),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final timeField = _TimeField(time: form.time, onTap: onPickTime);
              final statusField = _StatusField(form: form);
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    timeField,
                    const SizedBox(height: AppSpacing.md),
                    statusField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: timeField),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: statusField),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: form.noteController,
            label: 'Shift Note / Batch Reason',
            hintText: 'e.g. Bus shuttle arrival, Warehouse morning dispatch',
          ),
        ],
      ),
    );
  }
}

InputDecoration _decoration() => InputDecoration(
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.sm,
  ),
  border: OutlineInputBorder(
    borderRadius: AppSpacing.roundedSm,
    borderSide: const BorderSide(color: AppColors.outlineSubtle),
  ),
);

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primaryContainer,
      labelStyle: AppTypography.labelLarge.copyWith(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? AppColors.onPrimaryContainer : AppColors.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedSm,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.outlineSubtle,
        ),
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Check-In Time'),
        Semantics(
          button: true,
          label: 'Check-in time ${time.format(context)}. Tap to change.',
          child: InkWell(
            onTap: onTap,
            borderRadius: AppSpacing.roundedSm,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineSubtle),
                borderRadius: AppSpacing.roundedSm,
                color: AppColors.surfaceContainerLowest,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    time.format(context),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusField extends StatelessWidget {
  const _StatusField({required this.form});

  final GroupAttendanceFormController form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Punctuality Status'),
        DropdownButtonFormField<AttendanceStatus>(
          initialValue: form.status,
          isExpanded: true,
          decoration: _decoration(),
          items: const [
            DropdownMenuItem(
              value: AttendanceStatus.present,
              child: Text('Present (On Time)'),
            ),
            DropdownMenuItem(
              value: AttendanceStatus.late,
              child: Text('Late Arrival'),
            ),
          ],
          onChanged: (value) {
            if (value != null) form.setStatus(value);
          },
        ),
      ],
    );
  }
}
