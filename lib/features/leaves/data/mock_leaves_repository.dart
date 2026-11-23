import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/data/mock_leave_preview_calculator.dart';
import 'package:workaxis/features/leaves/data/mock_leaves_data_source.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_status_counts.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';
import 'package:workaxis/features/leaves/domain/repositories/leaves_repository.dart';
import 'package:workaxis/features/leaves/domain/services/leave_request_order.dart';
import 'package:workaxis/features/leaves/domain/services/leave_scope.dart';

class MockLeavesRepository implements LeavesRepository {
  MockLeavesRepository(
    this._dataSource, {
    this._scope = const LeaveScope(),
    this._calculator = const MockLeavePreviewCalculator(),
    Now? now,
    this.delay = const Duration(milliseconds: 140),
  }) : _now = now ?? systemNow;

  final MockLeavesDataSource _dataSource;
  final LeaveScope _scope;
  final MockLeavePreviewCalculator _calculator;
  final Now _now;
  final Duration delay;

  @override
  Future<PageResult<LeaveRequest>> getLeaveRequestsPage({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
    LeaveStatus? status,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    await Future<void>.delayed(delay);
    final matching =
        _inQueue(access, _scope.forRead(access, activeBranchId, queue))
            .where((request) => status == null || request.status == status)
            .toList()
          ..sort(compareLeaveRequests);
    return PageResult(
      items: matching.skip(offset).take(limit).toList(growable: false),
      total: matching.length,
      offset: offset,
    );
  }

  @override
  Future<LeaveStatusCounts> getLeaveStatusCounts({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
  }) async {
    await Future<void>.delayed(delay);
    final requests = _inQueue(
      access,
      _scope.forRead(access, activeBranchId, queue),
    );
    int count(LeaveStatus status) =>
        requests.where((request) => request.status == status).length;
    return LeaveStatusCounts(
      pending: count(LeaveStatus.pending),
      approved: count(LeaveStatus.approved),
      rejected: count(LeaveStatus.rejected),
    );
  }

  /// Mirrors the server scopes: own requests, employee requests of the
  /// active branch, or the whole organization.
  Iterable<LeaveRequest> _inQueue(
    UserAccessContext access,
    LeaveReadScope scope,
  ) {
    final organizationId = access.organization!.id;
    return _dataSource.requests.where((request) {
      if (request.organizationId != organizationId) return false;
      return switch (scope.queue) {
        LeaveQueue.mine => request.applicantUid == access.user.id,
        LeaveQueue.branchEmployees =>
          request.applicantRole == UserRole.employee &&
              request.branchId == scope.branch?.id,
        LeaveQueue.organization => true,
      };
    });
  }

  @override
  Future<List<LeaveTypeOption>> getLeaveTypes({
    required UserAccessContext access,
  }) async {
    await Future<void>.delayed(delay);
    _scope.assertMember(access);
    return _dataSource.leaveTypes;
  }

  @override
  Future<LeavePreview> previewLeaveDraft({
    required UserAccessContext access,
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    String? editingRequestId,
  }) async {
    await Future<void>.delayed(delay);
    _scope.assertApplicant(access);
    if (_date(endDate).isBefore(_date(startDate))) {
      throw ValidationException('End date must be on or after the start date.');
    }
    return _preview(
      access,
      applicantUid: access.user.id,
      leaveTypeId: leaveTypeId,
      startDate: startDate,
      endDate: endDate,
      excludeRequestId: editingRequestId,
    );
  }

  @override
  Future<LeavePreview> previewLeaveReview({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
  }) async {
    await Future<void>.delayed(delay);
    _scope.forReview(access, activeBranchId: activeBranchId, request: request);
    return _preview(
      access,
      applicantUid: request.applicantUid,
      leaveTypeId: request.leaveTypeId,
      startDate: request.startDate,
      endDate: request.endDate,
      excludeRequestId: request.id,
    );
  }

  LeavePreview _preview(
    UserAccessContext access, {
    required String applicantUid,
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeRequestId,
  }) {
    final type = _dataSource.leaveType(leaveTypeId);
    if (type == null) {
      throw const NotFoundException(
        'Leave type not found.',
        userMessage: 'Leave type not found.',
      );
    }
    final organizationId = access.organization!.id;
    return _calculator.preview(
      type: type.type,
      yearlyDays: type.yearlyDays,
      startDate: _date(startDate),
      endDate: _date(endDate),
      applicantRequests: _dataSource.requests.where(
        (request) =>
            request.organizationId == organizationId &&
            request.applicantUid == applicantUid,
      ),
      excludeRequestId: excludeRequestId,
    );
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
    final type = _validateDraft(draft);
    final request = LeaveRequest(
      id: _dataSource.nextId(),
      organizationId: access.organization!.id,
      branchId: branch.id,
      branchName: branch.name,
      applicantMemberId: access.user.id,
      applicantUid: access.user.id,
      applicantName: access.user.name,
      applicantRole: access.user.role,
      leaveTypeId: type.id,
      leaveTypeName: type.name,
      leaveTypePaid: type.paid,
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
    final type = _validateDraft(draft);
    final updated = request.copyWith(
      leaveTypeId: type.id,
      leaveTypeName: type.name,
      leaveTypePaid: type.paid,
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

  /// Validates [draft] and returns its (active) leave type.
  LeaveTypeOption _validateDraft(LeaveRequestDraft draft) {
    final type = _dataSource.leaveType(draft.leaveTypeId)?.type;
    if (type == null) {
      throw ValidationException('Choose an available leave type.');
    }
    if (draft.reason.trim().isEmpty || draft.reason.trim().length > 2000) {
      throw ValidationException('Enter a reason for the leave request.');
    }
    if (_date(draft.endDate).isBefore(_date(draft.startDate))) {
      throw ValidationException('End date must be on or after the start date.');
    }
    return type;
  }

  DateTime _date(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
