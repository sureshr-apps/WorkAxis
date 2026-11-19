import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

class LeavesRemoteDataSource {
  const LeavesRemoteDataSource(this._gateway);

  final DataGateway _gateway;

  Future<List<LeaveRequest>> listMine({
    required int limit,
    required int offset,
  }) async {
    final data = await _gateway.call('ListMyLeaveRequests', {
      'limit': limit,
      'offset': offset,
    });
    return _list(data);
  }

  Future<List<LeaveRequest>> listByOrganization({
    required int limit,
    required int offset,
  }) async {
    final data = await _gateway.call('ListOrganizationLeaveRequestsPaged', {
      'limit': limit,
      'offset': offset,
    });
    return _list(data);
  }

  Future<List<LeaveRequest>> listEmployeeRequestsByBranch({
    required String branchId,
    required int limit,
    required int offset,
  }) async {
    final data = await _gateway.call('ListEmployeeLeaveRequestsByBranchPaged', {
      'branchId': branchId,
      'limit': limit,
      'offset': offset,
    });
    return _list(data);
  }

  Future<LeaveRequest> submit({
    required String branchId,
    String? activeBranchId,
    required LeaveRequestDraft draft,
  }) async {
    final data = await _gateway.call('SubmitLeaveRequest', {
      'branchId': branchId,
      'activeBranchId': ?activeBranchId,
      'leaveType': draft.leaveType.name,
      'startDate': _dateOnly(draft.startDate),
      'endDate': _dateOnly(draft.endDate),
      'reason': draft.reason.trim(),
    });
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
      'leaveType': draft.leaveType.name,
      'startDate': _dateOnly(draft.startDate),
      'endDate': _dateOnly(draft.endDate),
      'reason': draft.reason.trim(),
    });
    return _map(data.object('leaveRequest'));
  }

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

  List<LeaveRequest> _list(Map<String, dynamic> data) => [
    for (final row in data.objects('leaveRequests')) _map(row),
  ];

  LeaveRequest _map(Map<String, dynamic> row) {
    final role = UserRoleValue.parse(_string(row, 'applicantRole'));
    final type = LeaveType.tryParse(_string(row, 'leaveType'));
    final status = LeaveStatus.tryParse(_string(row, 'status'));
    if (type == null || status == null) {
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
      leaveType: type,
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
