import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/maps/map_location_picker.dart';
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
  late final TextEditingController _referenceController;
  late final TextEditingController _evidenceController;
  late final bool _branchLocked;
  late final List<BranchSummary> _branches;
  String? _branchId;
  String? _assigneeId;
  String? _titleError;
  String? _destinationError;
  String? _assigneeError;
  String? _formError;
  double? _destinationLatitude;
  double? _destinationLongitude;
  DateTime? _dueAt;
  List<OrganizationMember> _assignees = const [];
  bool _loadingAssignees = false;
  bool _isSaving = false;
  int _assigneeLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _instructionsController = TextEditingController();
    _referenceController = TextEditingController();
    _evidenceController = TextEditingController();
    _branchLocked = widget.access.user.role == UserRole.branchManager;
    _branches = widget.access.activeAssignedBranches;
    _branchId = _branchLocked
        ? widget.activeBranchId
        : widget.access.activeBranch?.branchId ?? _branches.firstOrNull?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAssignees());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _referenceController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignees() async {
    final generation = ++_assigneeLoadGeneration;
    final branchId = _branchId;
    if (branchId == null) {
      setState(() {
        _assignees = const [];
        _assigneeId = null;
        _loadingAssignees = false;
      });
      return;
    }
    setState(() {
      _loadingAssignees = true;
      _assignees = const [];
      _assigneeId = null;
      _assigneeError = null;
      _formError = null;
    });
    try {
      final assignees = <OrganizationMember>[];
      final roles = _branchLocked
          ? const [UserRole.employee]
          : const [UserRole.employee, UserRole.branchManager];
      for (final role in roles) {
        final roleMembers = <OrganizationMember>[];
        var offset = 0;
        while (roleMembers.length < 1000) {
          final page = await widget.membersRepository.getMembersPage(
            access: widget.access,
            activeBranchId: _branchLocked ? branchId : null,
            role: role,
            status: AccountStatus.active,
            offset: offset,
            limit: 100,
          );
          roleMembers.addAll(page.items);
          if (!page.hasMore) break;
          offset = page.nextOffset;
        }
        assignees.addAll(roleMembers);
      }
      if (!mounted || generation != _assigneeLoadGeneration) return;
      setState(() {
        _assignees =
            assignees
                .where(
                  (assignee) =>
                      assignee.branchIds.contains(branchId) &&
                      assignee.authUid != null,
                )
                .toList()
              ..sort((a, b) => a.fullName.compareTo(b.fullName));
      });
    } catch (_) {
      if (mounted && generation == _assigneeLoadGeneration) {
        setState(
          () => _formError = 'Assignee list could not be loaded. Try again.',
        );
      }
    } finally {
      if (mounted && generation == _assigneeLoadGeneration) {
        setState(() => _loadingAssignees = false);
      }
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
    setState(() {
      _titleError = title.isEmpty
          ? 'Enter a title.'
          : title.length > 120
          ? 'Use 120 characters or fewer.'
          : null;
      _destinationError =
          _destinationLatitude == null || _destinationLongitude == null
          ? 'Choose a destination on the map.'
          : null;
      _assigneeError = _assigneeId == null ? 'Choose an assignee.' : null;
      _formError = null;
    });
    return _branchId != null &&
        _titleError == null &&
        _destinationError == null &&
        _assigneeError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final branchId = _branchId;
    final assigneeId = _assigneeId;
    if (branchId == null || assigneeId == null) return;
    setState(() => _isSaving = true);
    final saved = await widget.onSubmit(
      OffSiteWorkAssignmentDraft(
        branchId: branchId,
        employeeMemberId: assigneeId,
        title: _titleController.text.trim(),
        destination:
            '${_destinationLatitude!.toStringAsFixed(6)}, '
            '${_destinationLongitude!.toStringAsFixed(6)}',
        destinationLatitude: _destinationLatitude!,
        destinationLongitude: _destinationLongitude!,
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
                'The assignee records start, arrival, outcome, and return. Each step stores one location and does not change attendance.',
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
                          _loadAssignees();
                        },
                ),
              const SizedBox(height: AppSpacing.md),
              if (_assignees.isEmpty && !_loadingAssignees)
                Text(
                  _branchLocked
                      ? 'No active employees with sign-in access are assigned to this branch.'
                      : 'No active employees or Branch Managers with sign-in access are assigned to this branch.',
                ),
              DropdownButtonFormField<String>(
                initialValue:
                    _assignees.any((assignee) => assignee.id == _assigneeId)
                    ? _assigneeId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Assignee',
                  helperText: _loadingAssignees ? 'Loading assignees…' : null,
                  errorText: _assigneeError,
                ),
                items: [
                  for (final assignee in _assignees)
                    DropdownMenuItem(
                      value: assignee.id,
                      child: Text(
                        '${assignee.fullName} · ${assignee.role == UserRole.branchManager ? 'Branch Manager' : 'Employee'}',
                      ),
                    ),
                ],
                onChanged: _isSaving || _loadingAssignees
                    ? null
                    : (id) => setState(() => _assigneeId = id),
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
              MapLocationPicker(
                latitude: _destinationLatitude,
                longitude: _destinationLongitude,
                onLocationSelected: (latitude, longitude) {
                  setState(() {
                    _destinationLatitude = latitude;
                    _destinationLongitude = longitude;
                    _destinationError = null;
                  });
                },
                locationLabel: 'Off-site destination',
                selectionTitle: 'Select destination on map',
                selectionHelpText: 'Pan the map and tap the destination, or drag the selected pin.',
              ),
              if (_destinationError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _destinationError!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
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
          onPressed: _isSaving || _loadingAssignees || _branches.isEmpty
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
