import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/idempotent_creates.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_status_counts.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';

class LeavesRemoteDataSource {
  LeavesRemoteDataSource(this._gateway, {IdempotentCreates? creates})
    : _creates = creates ?? IdempotentCreates();

  final DataGateway _gateway;
  final IdempotentCreates _creates;

  /// One page of [queue]. [branchId] is required for
  /// [LeaveQueue.branchEmployees] and ignored otherwise.
  Future<PageResult<LeaveRequest>> listPage({
    required LeaveQueue queue,
    String? branchId,
    LeaveStatus? status,
    required int limit,
    required int offset,
  }) async {
    final data = await _gateway.call(_listOperation(queue), {
      if (queue == LeaveQueue.branchEmployees) 'branchId': _branch(branchId),
      'limit': limit,
      'offset': offset,
      // Unset optional variables are omitted, never sent as null.
      'status': ?status?.name,
    });
    return PageResult(
      items: [for (final row in data.objects('leaveRequests')) _map(row)],
      total: data.countOf('total'),
      offset: offset,
    );
  }

  /// Per-status totals for the whole of [queue].
  Future<LeaveStatusCounts> statusCounts({
    required LeaveQueue queue,
    String? branchId,
  }) async {
    final data = await _gateway.call('GetLeaveStatusCounts', {
      'scope': queue.scopeName,
      if (queue == LeaveQueue.branchEmployees) 'branchId': _branch(branchId),
    });
    final counts = data.object('counts');
    return LeaveStatusCounts(
      pending: counts.integer('pending'),
      approved: counts.integer('approved'),
      rejected: counts.integer('rejected'),
    );
  }

  static String _listOperation(LeaveQueue queue) => switch (queue) {
    LeaveQueue.mine => 'ListMyLeaveRequests',
    LeaveQueue.branchEmployees => 'ListEmployeeLeaveRequestsByBranchPaged',
    LeaveQueue.organization => 'ListOrganizationLeaveRequestsPaged',
  };

  static String _branch(String? branchId) {
    if (branchId == null || branchId.isEmpty) {
      throw ArgumentError('branchId is required for branch employee leave.');
    }
    return branchId;
  }

  Future<LeaveRequest> submit({
    required String branchId,
    String? activeBranchId,
    required LeaveRequestDraft draft,
  }) async {
    // A retried request reuses its requestId, so it is never saved twice.
    final data = await _creates.run('SubmitLeaveRequest', {
      'branchId': branchId,
      'activeBranchId': ?activeBranchId,
      'leaveTypeId': draft.leaveTypeId,
      'startDate': _dateOnly(draft.startDate),
      'endDate': _dateOnly(draft.endDate),
      'reason': draft.reason.trim(),
    }, (vars) => _gateway.call('SubmitLeaveRequest', vars));
    return _map(data.object('leaveRequest'));
  }

  Future<LeaveRequest> updatePending({
    required String requestId,
    String? activeBranchId,
    required LeaveRequestDraft draft,
  }) async {
    final data = await _gateway.call('UpdateMyPendingLeaveRequest', {
      'id': requestId,
      'activeBranchId': ?activeBranchId,
      'leaveTypeId': draft.leaveTypeId,
      'startDate': _dateOnly(draft.startDate),
      'endDate': _dateOnly(draft.endDate),
      'reason': draft.reason.trim(),
    });
    return _map(data.object('leaveRequest'));
  }

  /// The organization's active leave types, in display order.
  Future<List<LeaveTypeOption>> listLeaveTypes() async {
    final data = await _gateway.call('ListLeaveTypes', const {});
    return [
      for (final row in data.objects('leaveTypes'))
        LeaveTypeOption(
          id: row.string('id'),
          name: row.string('name'),
          paid: row.boolean('paid'),
        ),
    ];
  }

  /// Applicant preview of an unsaved draft. [requestId] is the pending
  /// request being edited, if any.
  Future<LeavePreview> previewDraft({
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    String? requestId,
  }) async {
    final data = await _gateway.call('PreviewLeaveRequest', {
      'leaveTypeId': leaveTypeId,
      'startDate': _dateOnly(startDate),
      'endDate': _dateOnly(endDate),
      'id': ?requestId,
    });
    return _mapPreview(data.object('leavePreview'));
  }

  /// Reviewer preview of a saved request. [activeBranchId] is required by the
  /// server for Branch Managers and omitted for Organization Admins.
  Future<LeavePreview> previewReview({
    required String requestId,
    String? activeBranchId,
  }) async {
    final data = await _gateway.call('PreviewLeaveRequest', {
      'id': requestId,
      'activeBranchId': ?activeBranchId,
    });
    return _mapPreview(data.object('leavePreview'));
  }

  LeavePreview _mapPreview(Map<String, dynamic> row) => LeavePreview(
    leaveTypeId: row.string('leaveTypeId'),
    availableDays: row.integer('availableDays'),
    workdays: row.integer('workdays'),
    paidDays: row.integer('paidDays'),
    unpaidDays: row.integer('unpaidDays'),
  );

  Future<LeaveRequest> review({
    required String requestId,
    String? activeBranchId,
    required LeaveStatus decision,
    String? reviewerNotes,
  }) async {
    final data = await _gateway.call('ReviewLeaveRequest', {
      'id': requestId,
      'activeBranchId': ?activeBranchId,
      'status': decision.name,
      'reviewerNotes': ?reviewerNotes?.trim(),
    });
    return _map(data.object('leaveRequest'));
  }

  LeaveRequest _map(Map<String, dynamic> row) {
    final role = UserRoleValue.parse(_string(row, 'applicantRole'));
    final status = LeaveStatus.tryParse(_string(row, 'status'));
    if (status == null) {
      throw const DatabaseException(
        'Invalid leave request enum returned by the server.',
      );
    }
    return LeaveRequest(
      id: _string(row, 'id'),
      organizationId: _string(row, 'organizationId'),
      branchId: _string(row, 'branchId'),
      branchName: _string(row, 'branchName'),
      applicantMemberId: _string(row, 'applicantMemberId'),
      applicantUid: _string(row, 'applicantUid'),
      applicantName: _string(row, 'applicantName'),
      applicantRole: role,
      // `leaveType` is only the legacy code of a former fixed type; the
      // organization-defined type is identified by id.
      leaveTypeId: _string(row, 'leaveTypeId'),
      leaveTypeName: _string(row, 'leaveTypeName'),
      leaveTypePaid: row.boolean('leaveTypePaid'),
      startDate: _calendarDate(row, 'startDate'),
      endDate: _calendarDate(row, 'endDate'),
      reason: _string(row, 'reason'),
      status: status,
      reviewerUid: _optionalString(row, 'reviewerUid'),
      reviewerName: _optionalString(row, 'reviewerName'),
      reviewerNotes: _optionalString(row, 'reviewerNotes'),
      reviewedAt: _optionalInstant(row, 'reviewedAt'),
      createdAt: _optionalInstant(row, 'createdAt'),
    );
  }

  String _string(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! String) {
      throw DatabaseException('Leave response is missing $key.');
    }
    return value;
  }

  String? _optionalString(Map<String, dynamic> row, String key) =>
      row[key] is String ? row[key] as String : null;

  DateTime _calendarDate(Map<String, dynamic> row, String key) {
    final value = _string(row, key);
    final parts = value.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((part) => part == null)) {
      throw DatabaseException('Leave response has an invalid $key.');
    }
    return DateTime(parts[0]!, parts[1]!, parts[2]!);
  }

  DateTime? _optionalInstant(Map<String, dynamic> row, String key) {
    final value = row[key];
    return value is String ? DateTime.tryParse(value) : null;
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

abstract final class UserRoleValue {
  static UserRole parse(String value) {
    for (final role in UserRole.values) {
      if (role.name == value) return role;
    }
    throw const DatabaseException(
      'Invalid applicant role returned by the server.',
    );
  }
}
