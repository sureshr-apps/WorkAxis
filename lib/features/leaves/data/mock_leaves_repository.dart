import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/data/mock_leaves_data_source.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/repositories/leaves_repository.dart';
import 'package:workaxis/features/leaves/domain/services/leave_scope.dart';

class MockLeavesRepository implements LeavesRepository {
  MockLeavesRepository(
    this._dataSource, {
    this._scope = const LeaveScope(),
    Now? now,
    this.delay = const Duration(milliseconds: 140),
  }) : _now = now ?? systemNow;

  final MockLeavesDataSource _dataSource;
  final LeaveScope _scope;
  final Now _now;
  final Duration delay;

  @override
  Future<List<LeaveRequest>> getLeaveRequests({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    await Future<void>.delayed(delay);
    final scope = _scope.forRead(access, activeBranchId);
    final organizationId = access.organization!.id;
    final branchId = scope.activeBranch?.id;
    final requests = _dataSource.requests.where((request) {
      if (request.organizationId != organizationId) return false;
      if (scope.ownOnly) return request.applicantUid == access.user.id;
      if (scope.organizationWide) return true;
      return request.applicantUid == access.user.id ||
          (request.applicantRole == UserRole.employee &&
              request.branchId == branchId);
    }).toList();
    return _sorted(requests);
  }

  @override
  Future<LeaveRequest> submitLeaveRequest({
    required UserAccessContext access,
    String? branchId,
    String? activeBranchId,
    required LeaveRequestDraft draft,
  }) async {
    await Future<void>.delayed(delay);
    final branch = _scope.forSubmit(
      access,
      branchId: branchId,
      activeBranchId: activeBranchId,
    );
    _validateDraft(draft);
    final request = LeaveRequest(
      id: _dataSource.nextId(),
      organizationId: access.organization!.id,
      branchId: branch.id,
      branchName: branch.name,
      applicantMemberId: access.user.id,
      applicantUid: access.user.id,
      applicantName: access.user.name,
      applicantRole: access.user.role,
      leaveType: draft.leaveType,
      startDate: _date(draft.startDate),
      endDate: _date(draft.endDate),
      reason: draft.reason.trim(),
      status: LeaveStatus.pending,
      createdAt: _now(),
    );
    _dataSource.save(request);
    return request;
  }

  @override
  Future<LeaveRequest> updatePendingLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveRequestDraft draft,
  }) async {
    await Future<void>.delayed(delay);
    _scope.assertCanEditPending(
      access,
      request,
      activeBranchId: activeBranchId,
    );
    _validateDraft(draft);
    final updated = request.copyWith(
      leaveType: draft.leaveType,
      startDate: _date(draft.startDate),
      endDate: _date(draft.endDate),
      reason: draft.reason.trim(),
    );
    _dataSource.save(updated);
    return updated;
  }

  @override
  Future<LeaveRequest> reviewLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveStatus decision,
    String? reviewerNotes,
  }) async {
    await Future<void>.delayed(delay);
    _scope.forReview(access, activeBranchId: activeBranchId, request: request);
    if (request.status != LeaveStatus.pending ||
        decision == LeaveStatus.pending) {
      throw ValidationException('Only pending leave requests can be reviewed.');
    }
    final updated = request.copyWith(
      status: decision,
      reviewerUid: access.user.id,
      reviewerName: access.user.name,
      reviewerNotes: reviewerNotes?.trim(),
      reviewedAt: _now(),
    );
    _dataSource.save(updated);
    return updated;
  }

  void _validateDraft(LeaveRequestDraft draft) {
    if (draft.reason.trim().isEmpty || draft.reason.trim().length > 2000) {
      throw ValidationException('Enter a reason for the leave request.');
    }
    if (_date(draft.endDate).isBefore(_date(draft.startDate))) {
      throw ValidationException('End date must be on or after the start date.');
    }
  }

  DateTime _date(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  List<LeaveRequest> _sorted(List<LeaveRequest> requests) {
    requests.sort((a, b) {
      final pendingOrder = (a.status == LeaveStatus.pending ? 0 : 1).compareTo(
        b.status == LeaveStatus.pending ? 0 : 1,
      );
      return pendingOrder != 0
          ? pendingOrder
          : a.startDate.compareTo(b.startDate);
    });
    return requests;
  }
}
