import 'package:flutter/material.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/domain/services/group_attendance_eligibility.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

/// UI state and submission logic of the group check-in dialog.
class GroupAttendanceFormController extends ChangeNotifier {
  GroupAttendanceFormController({
    required this.access,
    required this.membersRepository,
    required this.existingEntries,
    required this.onSubmit,
    required DateTime initialDate,
    String? initialBranchId,
    this.failureMessage,
  }) : _selectedDate = initialDate,
       _branchId =
           initialBranchId ??
           (access.assignedBranches.isNotEmpty
               ? access.assignedBranches.first.id
               : null);

  static const shifts = ['Morning Shift', 'Afternoon Shift', 'Night Shift'];
  static const _eligibility = GroupAttendanceEligibility();

  final UserAccessContext access;
  final OrganizationMembersRepository membersRepository;
  final List<AttendanceEntry> existingEntries;
  final Future<bool> Function(GroupAttendanceRequest request) onSubmit;

  /// Reads the failure reason the owner recorded when [onSubmit] returned false.
  final String? Function()? failureMessage;

  final TextEditingController noteController = TextEditingController();

  String? _branchId;
  final DateTime _selectedDate;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 30);
  String _shift = shifts.first;
  AttendanceStatus _status = AttendanceStatus.present;
  List<OrganizationMember> _members = const [];
  final Set<String> _selectedIds = {};
  bool _isLoadingMembers = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _searchQuery = '';
  int _loadToken = 0;
  bool _disposed = false;

  String? get branchId => _branchId;
  TimeOfDay get time => _time;
  String get shift => _shift;
  AttendanceStatus get status => _status;
  bool get isLoadingMembers => _isLoadingMembers;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  int get selectedCount => _selectedIds.length;
  int get memberCount => _members.length;
  bool isSelected(OrganizationMember member) =>
      _selectedIds.contains(member.id);

  /// Whether [member] already has a check-in on the selected day.
  bool isRecorded(OrganizationMember member) => _eligibility.hasRecorded(
    _eligibility.attendanceId(member),
    existingEntries,
    _selectedDate,
  );

  /// Roster rows matching the search box.
  List<OrganizationMember> get visibleMembers {
    if (_searchQuery.isEmpty) return _members;
    return _members
        .where(
          (m) =>
              m.fullName.toLowerCase().contains(_searchQuery) ||
              m.username.toLowerCase().contains(_searchQuery),
        )
        .toList(growable: false);
  }

  Future<void> loadMembers() async {
    final token = ++_loadToken;
    _isLoadingMembers = true;
    _errorMessage = null;
    _notify();
    try {
      final all = await membersRepository.getMembers(
        access: access,
        activeBranchId: _branchId,
      );
      if (_disposed || token != _loadToken) return;
      _members = _eligibility.eligibleMembers(all, branchId: _branchId);
      _selectedIds
        ..clear()
        ..addAll(
          _eligibility
              .unrecordedMembers(
                _members,
                branchId: _branchId,
                entries: existingEntries,
                day: _selectedDate,
              )
              .map((m) => m.id),
        );
    } catch (e, st) {
      if (_disposed || token != _loadToken) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load branch employee roster.',
      );
    }
    _isLoadingMembers = false;
    _notify();
  }

  void selectBranch(String id) {
    _branchId = id;
    loadMembers();
  }

  void setTime(TimeOfDay value) {
    _time = value;
    _notify();
  }

  void setShift(String value) {
    _shift = value;
    _notify();
  }

  void setStatus(AttendanceStatus value) {
    _status = value;
    _notify();
  }

  void setSearch(String query) {
    _searchQuery = query.trim().toLowerCase();
    _notify();
  }

  void toggle(OrganizationMember member, bool selected) {
    selected ? _selectedIds.add(member.id) : _selectedIds.remove(member.id);
    _notify();
  }

  void selectAllUnrecorded() {
    for (final m in _members.where((m) => !isRecorded(m))) {
      _selectedIds.add(m.id);
    }
    _notify();
  }

  void clearSelection() {
    _selectedIds.clear();
    _notify();
  }

  /// Submits the batch. Returns true only when it was recorded; otherwise
  /// [errorMessage] explains why.
  Future<bool> submit() async {
    final branch = _branchId;
    if (branch == null) {
      _errorMessage = 'Please select a branch.';
      _notify();
      return false;
    }
    if (_selectedIds.isEmpty) {
      _errorMessage = 'Select at least one employee.';
      _notify();
      return false;
    }
    final attendees = _members
        .where((m) => _selectedIds.contains(m.id))
        .map(
          (m) => GroupAttendanceAttendee(
            employeeId: _eligibility.attendanceId(m),
            employeeName: m.fullName,
          ),
        )
        .toList();
    final note = noteController.text.trim();
    final request = GroupAttendanceRequest(
      branchId: branch,
      workDate: _selectedDate,
      checkInAt: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _time.hour,
        _time.minute,
      ),
      attendees: attendees,
      shiftName: _shift,
      status: _status,
      note: note.isEmpty ? null : note,
    );

    _isSubmitting = true;
    _errorMessage = null;
    _notify();
    var success = false;
    try {
      success = await onSubmit(request);
      if (!success) {
        _errorMessage =
            failureMessage?.call() ??
            'Could not record group attendance. Try again.';
      }
    } catch (e, st) {
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not record group attendance. Try again.',
      );
    }
    _isSubmitting = false;
    _notify();
    return success;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    noteController.dispose();
    super.dispose();
  }
}
