import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';

/// A mock organization leave type with its yearly allowance.
typedef MockLeaveTypeAllowance = ({LeaveTypeOption type, int yearlyDays});

class MockLeavesDataSource {
  MockLeavesDataSource({Now? now}) : _now = now ?? systemNow {
    _seed();
  }

  /// Leave types every mock organization offers, in display order.
  static const List<MockLeaveTypeAllowance> seededLeaveTypes = [
    (
      type: LeaveTypeOption(id: 'lt-annual', name: 'Annual leave', paid: true),
      yearlyDays: 12,
    ),
    (
      type: LeaveTypeOption(id: 'lt-sick', name: 'Sick leave', paid: true),
      yearlyDays: 6,
    ),
    (
      type: LeaveTypeOption(
        id: 'lt-personal',
        name: 'Personal leave',
        paid: true,
      ),
      yearlyDays: 2,
    ),
    (
      type: LeaveTypeOption(id: 'lt-unpaid', name: 'Unpaid leave', paid: false),
      yearlyDays: 0,
    ),
  ];

  final Now _now;
  final List<LeaveRequest> _requests = [];
  int _nextId = 5;

  List<LeaveRequest> get requests => List.unmodifiable(_requests);

  List<LeaveTypeOption> get leaveTypes => [
    for (final entry in seededLeaveTypes) entry.type,
  ];

  /// The active type [id] with its allowance, or null when unknown.
  MockLeaveTypeAllowance? leaveType(String id) =>
      seededLeaveTypes.where((entry) => entry.type.id == id).firstOrNull;

  String nextId() => 'LV-${(_nextId++).toString().padLeft(3, '0')}';

  void save(LeaveRequest request) {
    final index = _requests.indexWhere((item) => item.id == request.id);
    if (index == -1) {
      _requests.insert(0, request);
    } else {
      _requests[index] = request;
    }
  }

  void _seed() {
    final today = _date(_now());
    final annual = seededLeaveTypes[0].type;
    final sick = seededLeaveTypes[1].type;
    final personal = seededLeaveTypes[2].type;
    _requests.addAll([
      LeaveRequest(
        id: 'LV-001',
        organizationId: 'org-acme',
        branchId: 'br-01',
        branchName: 'Downtown Flagship',
        applicantMemberId: 'user-emp-01',
        applicantUid: 'user-emp-01',
        applicantName: 'Sarah Connor',
        applicantRole: UserRole.employee,
        leaveTypeId: annual.id,
        leaveTypeName: annual.name,
        leaveTypePaid: annual.paid,
        startDate: today.add(const Duration(days: 7)),
        endDate: today.add(const Duration(days: 8)),
        reason: 'Family commitment.',
        status: LeaveStatus.pending,
        createdAt: _now().subtract(const Duration(hours: 2)),
      ),
      LeaveRequest(
        id: 'LV-002',
        organizationId: 'org-acme',
        branchId: 'br-01',
        branchName: 'Downtown Flagship',
        applicantMemberId: 'user-bm-multi-01',
        applicantUid: 'user-bm-multi-01',
        applicantName: 'Marcus Chen',
        applicantRole: UserRole.branchManager,
        leaveTypeId: personal.id,
        leaveTypeName: personal.name,
        leaveTypePaid: personal.paid,
        startDate: today.add(const Duration(days: 14)),
        endDate: today.add(const Duration(days: 14)),
        reason: 'Personal appointment.',
        status: LeaveStatus.pending,
        createdAt: _now().subtract(const Duration(hours: 4)),
      ),
      LeaveRequest(
        id: 'LV-003',
        organizationId: 'org-acme',
        branchId: 'br-01',
        branchName: 'Downtown Flagship',
        applicantMemberId: 'user-emp-01',
        applicantUid: 'user-emp-01',
        applicantName: 'Sarah Connor',
        applicantRole: UserRole.employee,
        leaveTypeId: sick.id,
        leaveTypeName: sick.name,
        leaveTypePaid: sick.paid,
        startDate: today.subtract(const Duration(days: 5)),
        endDate: today.subtract(const Duration(days: 4)),
        reason: 'Recovery from illness.',
        status: LeaveStatus.approved,
        reviewerUid: 'user-oa-01',
        reviewerName: 'Jordan Lee',
        reviewerNotes: 'Approved.',
        reviewedAt: _now().subtract(const Duration(days: 6)),
        createdAt: _now().subtract(const Duration(days: 8)),
      ),
    ]);
  }

  DateTime _date(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
