import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

/// Modal dialog allowing Branch Managers and Organization Admins
/// to record batch attendance check-ins for a roster of employees.
class GroupAttendanceDialog extends StatefulWidget {
  final UserAccessContext access;
  final String? initialBranchId;
  final DateTime initialDate;
  final List<AttendanceEntry> existingEntries;
  final Future<bool> Function(GroupAttendanceRequest request) onSubmit;

  const GroupAttendanceDialog({
    super.key,
    required this.access,
    required this.initialBranchId,
    required this.initialDate,
    required this.existingEntries,
    required this.onSubmit,
  });

  @override
  State<GroupAttendanceDialog> createState() => _GroupAttendanceDialogState();
}

class _GroupAttendanceDialogState extends State<GroupAttendanceDialog> {
  late String? _selectedBranchId;
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 30);
  String _selectedShift = 'Morning Shift';
  AttendanceStatus _selectedStatus = AttendanceStatus.present;

  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  List<OrganizationMember> _members = [];
  final Set<String> _selectedMemberIds = {};
  bool _isLoadingMembers = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _searchQuery = '';

  static const List<String> _shifts = [
    'Morning Shift',
    'Afternoon Shift',
    'Night Shift',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedBranchId =
        widget.initialBranchId ??
        (widget.access.assignedBranches.isNotEmpty
            ? widget.access.assignedBranches.first.id
            : null);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _errorMessage = null;
    });

    try {
      final membersRepo = context.read<OrganizationMembersRepository>();
      final allMembers = await membersRepo.getMembers(
        access: widget.access,
        activeBranchId: _selectedBranchId,
      );

      // Only active employees assigned to this branch
      final eligible = allMembers.where((m) {
        final isActive = m.status == AccountStatus.active;
        final isEmp = m.role == UserRole.employee;
        final matchesBranch =
            _selectedBranchId == null ||
            m.branchIds.contains(_selectedBranchId);
        return isActive && isEmp && matchesBranch;
      }).toList();

      if (mounted) {
        setState(() {
          _members = eligible;
          _isLoadingMembers = false;

          // Pre-select unrecorded employees
          _selectedMemberIds.clear();
          for (final member in eligible) {
            final alreadyCheckedIn = widget.existingEntries.any(
              (e) =>
                  e.employeeId == member.id &&
                  e.status == AttendanceStatus.present,
            );
            if (!alreadyCheckedIn) {
              _selectedMemberIds.add(member.id);
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
          _errorMessage = 'Could not load branch employee roster.';
        });
      }
    }
  }

  bool _isAlreadyCheckedIn(String employeeId) {
    return widget.existingEntries.any(
      (e) =>
          e.employeeId == employeeId &&
          e.status == AttendanceStatus.present &&
          _sameDate(e.workDate, _selectedDate),
    );
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _selectAllUnrecorded() {
    setState(() {
      for (final m in _members) {
        if (!_isAlreadyCheckedIn(m.id)) {
          _selectedMemberIds.add(m.id);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMemberIds.clear();
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleSubmit() async {
    final branchId = _selectedBranchId;
    if (branchId == null) {
      setState(() => _errorMessage = 'Please select a branch.');
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      setState(() => _errorMessage = 'Select at least one employee.');
      return;
    }

    final selectedAttendees = _members
        .where((m) => _selectedMemberIds.contains(m.id))
        .map(
          (m) => GroupAttendanceAttendee(
            employeeId: m.id,
            employeeName: m.fullName,
          ),
        )
        .toList();

    final checkInDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final request = GroupAttendanceRequest(
      branchId: branchId,
      workDate: _selectedDate,
      checkInAt: checkInDateTime,
      attendees: selectedAttendees,
      shiftName: _selectedShift,
      status: _selectedStatus,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onSubmit(request);
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to submit group attendance.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;
    final filteredMembers = _members.where((m) {
      if (_searchQuery.isEmpty) return true;
      return m.fullName.toLowerCase().contains(_searchQuery) ||
          m.username.toLowerCase().contains(_searchQuery);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      backgroundColor: AppColors.surfaceContainerLowest,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.sm : AppSpacing.xl,
        vertical: isCompact ? AppSpacing.sm : AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(context),
            const Divider(height: 1, color: AppColors.outlineSubtle),

            // Content body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.statusUrgentContainer,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 18,
                              color: AppColors.statusUrgentText,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.statusUrgentText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Branch & Shift Controls
                    _buildConfigurationSection(context),
                    const SizedBox(height: AppSpacing.lg),

                    // Personnel Selection Roster
                    _buildRosterSection(filteredMembers),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.outlineSubtle),
            // Footer Action Bar
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.group_add_outlined,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Attendance Check-In',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Record simultaneous check-ins for shift roster employees.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.onSurfaceVariant,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSection(BuildContext context) {
    final canChangeBranch =
        widget.access.user.role == UserRole.orgAdmin &&
        widget.access.assignedBranches.length > 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch & Shift Row
          if (canChangeBranch) ...[
            const Text(
              'Branch Location',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<String>(
              initialValue: _selectedBranchId,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.outlineSubtle),
                ),
              ),
              items: widget.access.assignedBranches.map((b) {
                return DropdownMenuItem(
                  value: b.id,
                  child: Text(b.name, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (id) {
                if (id != null) {
                  setState(() => _selectedBranchId = id);
                  _loadMembers();
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Shift Picker
          const Text(
            'Shift',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: _shifts.map((shift) {
              final isSelected = _selectedShift == shift;
              return ChoiceChip(
                label: Text(shift),
                selected: isSelected,
                selectedColor: AppColors.primaryContainer,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurface,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.outlineSubtle,
                  ),
                ),
                onSelected: (_) => setState(() => _selectedShift = shift),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Time & Status Selection Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check-In Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineSubtle),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          color: AppColors.surfaceContainerLowest,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 14,
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
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Punctuality Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<AttendanceStatus>(
                      initialValue: _selectedStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.outlineSubtle,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AttendanceStatus.present,
                          child: Text(
                            'Present (On Time)',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: AttendanceStatus.late,
                          child: Text(
                            'Late Arrival',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Optional Note
          AppTextField(
            controller: _noteController,
            label: 'Shift Note / Batch Reason',
            hintText: 'e.g. Bus shuttle arrival, Warehouse morning dispatch',
          ),
        ],
      ),
    );
  }

  Widget _buildRosterSection(List<OrganizationMember> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personnel Roster',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  '${_selectedMemberIds.length} of ${members.length} selected',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _selectAllUnrecorded,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Select All',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _clearSelection,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Quick Search Field
        AppTextField.search(
          controller: _searchController,
          hintText: 'Filter by employee name or username...',
          onChanged: (query) {
            setState(() => _searchQuery = query.trim().toLowerCase());
          },
        ),
        const SizedBox(height: AppSpacing.sm),

        if (_isLoadingMembers)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (members.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Text(
              'No eligible active employees found for this branch.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outlineSubtle),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.outlineSubtle),
              itemBuilder: (context, index) {
                final member = members[index];
                final isCheckedIn = _isAlreadyCheckedIn(member.id);
                final isSelected = _selectedMemberIds.contains(member.id);

                return CheckboxListTile(
                  value: isSelected,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  activeColor: AppColors.primary,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedMemberIds.add(member.id);
                      } else {
                        _selectedMemberIds.remove(member.id);
                      }
                    });
                  },
                  secondary: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      member.initials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCheckedIn)
                        const StatusChip(
                          label: 'Checked In',
                          type: StatusType.active,
                          width: null,
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '@${member.username}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton.outlined(
            text: 'Cancel',
            isFullWidth: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton.primary(
            text: _isSubmitting
                ? 'Recording...'
                : 'Confirm Check-In (${_selectedMemberIds.length})',
            iconData: Icons.check,
            isFullWidth: false,
            onPressed: _isSubmitting ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }
}
