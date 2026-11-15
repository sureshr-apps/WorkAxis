import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/form_action_row.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_config_section.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_form_controller.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_roster.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Batch check-in page allowing Branch Managers and Organization Admins to
/// record attendance for a roster of employees.
///
/// The page only reports outcomes: [onClose] for back and cancel, and
/// [onSaved] after the batch was recorded. The route decides where to go next.
class GroupAttendanceScreen extends StatefulWidget {
  const GroupAttendanceScreen({
    super.key,
    required this.access,
    required this.initialBranchId,
    required this.initialDate,
    required this.existingEntries,
    required this.onSubmit,
    required this.onClose,
    required this.onSaved,
    required this.backLabel,
    this.failureMessage,
  });

  final UserAccessContext access;
  final String? initialBranchId;
  final DateTime initialDate;
  final List<AttendanceEntry> existingEntries;
  final Future<bool> Function(GroupAttendanceRequest request) onSubmit;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  /// Name of the list the page belongs to, shown in the breadcrumb.
  final String backLabel;

  /// Supplies the reason for the most recent failed submit, if known.
  final String? Function()? failureMessage;

  @override
  State<GroupAttendanceScreen> createState() => _GroupAttendanceScreenState();
}

class _GroupAttendanceScreenState extends State<GroupAttendanceScreen> {
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
    if (success && mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _form,
      builder: (context, _) => PopScope(
        // No leaving (system back, browser back) while the batch is recorded.
        canPop: !_form.isSubmitting,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                context.isCompact ? AppSpacing.md : AppSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PageBreadcrumb(
                        backLabel: widget.backLabel,
                        currentLabel: 'Group Check-In',
                        onBack: widget.onClose,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AppPageHeader(
                        eyebrow: 'Time & Attendance',
                        title: 'Group Attendance Check-In',
                        subtitle: 'Record simultaneous check-ins for shift roster employees.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DashboardSurfaceCard(
                        // ListTiles and checkboxes need a Material ancestor.
                        child: Material(
                          type: MaterialType.transparency,
                          child: _buildForm(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FormActionRow(
                        submitLabel:
                            'Confirm Check-In (${_form.selectedCount})',
                        submitIcon: Icons.check,
                        onCancel: widget.onClose,
                        onSubmit: _form.isSubmitting ? null : _submit,
                        isBusy: _form.isSubmitting,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
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
    );
  }
}
