import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_config_section.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_form_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_roster.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

/// Modal dialog allowing Branch Managers and Organization Admins to record
/// batch attendance check-ins for a roster of employees. Pops `true` only
/// after the batch was recorded.
class GroupAttendanceDialog extends StatefulWidget {
  const GroupAttendanceDialog({
    super.key,
    required this.access,
    required this.initialBranchId,
    required this.initialDate,
    required this.existingEntries,
    required this.onSubmit,
    this.failureMessage,
  });

  final UserAccessContext access;
  final String? initialBranchId;
  final DateTime initialDate;
  final List<AttendanceEntry> existingEntries;
  final Future<bool> Function(GroupAttendanceRequest request) onSubmit;

  /// Supplies the reason for the most recent failed submit, if known.
  final String? Function()? failureMessage;

  @override
  State<GroupAttendanceDialog> createState() => _GroupAttendanceDialogState();
}

class _GroupAttendanceDialogState extends State<GroupAttendanceDialog> {
  late final GroupAttendanceFormController _form;

  @override
  void initState() {
    super.initState();
    _form = GroupAttendanceFormController(
      access: widget.access,
      membersRepository: context.read<OrganizationMembersRepository>(),
      existingEntries: widget.existingEntries,
      onSubmit: widget.onSubmit,
      initialDate: widget.initialDate,
      initialBranchId: widget.initialBranchId,
      failureMessage: widget.failureMessage,
    )..loadMembers();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _form.time,
    );
    if (picked != null) _form.setTime(picked);
  }

  Future<void> _submit() async {
    final success = await _form.submit();
    if (success && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
      backgroundColor: AppColors.surfaceContainerLowest,
      insetPadding: EdgeInsets.all(isCompact ? AppSpacing.sm : AppSpacing.xl),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: ListenableBuilder(
          listenable: _form,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onClose: () => Navigator.of(context).pop()),
              const Divider(height: 1, color: AppColors.outlineSubtle),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_form.errorMessage != null) ...[
                        ErrorBanner(message: _form.errorMessage!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      GroupAttendanceConfigSection(
                        form: _form,
                        access: widget.access,
                        onPickTime: _pickTime,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      GroupAttendanceRoster(form: _form),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.outlineSubtle),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton.outlined(
                      text: 'Cancel',
                      isFullWidth: false,
                      onPressed: _form.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    AppButton.primary(
                      text: 'Confirm Check-In (${_form.selectedCount})',
                      iconData: Icons.check,
                      isFullWidth: false,
                      isLoading: _form.isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: AppSpacing.roundedSm,
            ),
            child: const Icon(
              Icons.group_add_outlined,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Attendance Check-In',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Record simultaneous check-ins for shift roster employees.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.onSurfaceVariant,
            tooltip: 'Close',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
