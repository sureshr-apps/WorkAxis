import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

class MockLeavesDataSource {
  MockLeavesDataSource({Now? now}) : _now = now ?? systemNow {
    _seed();
  }

  final Now _now;
  final List<LeaveRequest> _requests = [];
  int _nextId = 5;

  List<LeaveRequest> get requests => List.unmodifiable(_requests);

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
        leaveType: LeaveType.annual,
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
        leaveType: LeaveType.personal,
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
        leaveType: LeaveType.sick,
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
