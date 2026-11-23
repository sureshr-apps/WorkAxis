import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/data/leaves_remote_data_source.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_status_counts.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';
import 'package:workaxis/features/leaves/domain/repositories/leaves_repository.dart';
import 'package:workaxis/features/leaves/domain/services/leave_scope.dart';

class SqlConnectLeavesRepository implements LeavesRepository {
  SqlConnectLeavesRepository({
    required DataGateway gateway,
    this._scope = const LeaveScope(),
  }) : _remote = LeavesRemoteDataSource(gateway);

  final LeavesRemoteDataSource _remote;
  final LeaveScope _scope;

  @override
  Future<PageResult<LeaveRequest>> getLeaveRequestsPage({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
    LeaveStatus? status,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    try {
      final scope = _scope.forRead(access, activeBranchId, queue);
      return await _remote.listPage(
        queue: queue,
        branchId: scope.branch?.id,
        status: status,
        limit: limit,
        offset: offset,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<LeaveStatusCounts> getLeaveStatusCounts({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
  }) async {
    try {
      final scope = _scope.forRead(access, activeBranchId, queue);
      return await _remote.statusCounts(
        queue: queue,
        branchId: scope.branch?.id,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<List<LeaveTypeOption>> getLeaveTypes({
    required UserAccessContext access,
  }) async {
    try {
      _scope.assertMember(access);
      return await _remote.listLeaveTypes();
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<LeavePreview> previewLeaveDraft({
    required UserAccessContext access,
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    String? editingRequestId,
  }) async {
    try {
      _scope.assertApplicant(access);
      return await _remote.previewDraft(
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        requestId: editingRequestId,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<LeavePreview> previewLeaveReview({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
  }) async {
    try {
      _scope.forReview(
        access,
        activeBranchId: activeBranchId,
        request: request,
      );
      return await _remote.previewReview(
        requestId: request.id,
        activeBranchId: access.user.role == UserRole.branchManager
            ? activeBranchId ?? access.activeBranch?.branchId
            : null,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<LeaveRequest> submitLeaveRequest({
    required UserAccessContext access,
    String? branchId,
    String? activeBranchId,
    required LeaveRequestDraft draft,
  }) async {
    try {
      final branch = _scope.forSubmit(
        access,
        branchId: branchId,
        activeBranchId: activeBranchId,
      );
      return await _remote.submit(
        branchId: branch.id,
        activeBranchId: access.user.role == UserRole.branchManager
            ? activeBranchId ?? access.activeBranch?.branchId
            : null,
        draft: draft,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<LeaveRequest> updatePendingLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveRequestDraft draft,
  }) async {
    try {
      _scope.assertCanEditPending(
        access,
        request,
        activeBranchId: activeBranchId,
      );
      return await _remote.updatePending(
        requestId: request.id,
        activeBranchId: access.user.role == UserRole.branchManager
            ? activeBranchId ?? access.activeBranch?.branchId
            : null,
        draft: draft,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<LeaveRequest> reviewLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveStatus decision,
    String? reviewerNotes,
  }) async {
    try {
      _scope.forReview(
        access,
        activeBranchId: activeBranchId,
        request: request,
      );
      if (request.status != LeaveStatus.pending ||
          decision == LeaveStatus.pending) {
        throw ValidationException(
          'Only pending leave requests can be reviewed.',
        );
      }
      return await _remote.review(
        requestId: request.id,
        activeBranchId: activeBranchId,
        decision: decision,
        reviewerNotes: reviewerNotes,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
