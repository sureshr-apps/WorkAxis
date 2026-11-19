import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/data/leaves_remote_data_source.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/repositories/leaves_repository.dart';
import 'package:workaxis/features/leaves/domain/services/leave_scope.dart';

class SqlConnectLeavesRepository implements LeavesRepository {
  SqlConnectLeavesRepository({
    required DataGateway gateway,
    this._scope = const LeaveScope(),
  }) : _remote = LeavesRemoteDataSource(gateway);

  static const int pageSize = 100;

  final LeavesRemoteDataSource _remote;
  final LeaveScope _scope;

  @override
  Future<List<LeaveRequest>> getLeaveRequests({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    try {
      final scope = _scope.forRead(access, activeBranchId);
      if (scope.ownOnly) return await _loadPages(_remote.listMine);
      if (scope.organizationWide) {
        return await _loadPages(_remote.listByOrganization);
      }
      final branch = scope.activeBranch!;
      final lists = await Future.wait([
        _loadPages(_remote.listMine),
        _loadPages(
          ({required int limit, required int offset}) =>
              _remote.listEmployeeRequestsByBranch(
                branchId: branch.id,
                limit: limit,
                offset: offset,
              ),
        ),
      ]);
      final byId = <String, LeaveRequest>{
        for (final request in [...lists[0], ...lists[1]]) request.id: request,
      };
      return _sort(byId.values.toList());
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

  Future<List<LeaveRequest>> _loadPages(
    Future<List<LeaveRequest>> Function({
      required int limit,
      required int offset,
    })
    loadPage,
  ) async {
    final requests = <LeaveRequest>[];
    var offset = 0;
    while (true) {
      final page = await loadPage(limit: pageSize, offset: offset);
      requests.addAll(page);
      if (page.length < pageSize) return _sort(requests);
      offset += page.length;
    }
  }

  List<LeaveRequest> _sort(List<LeaveRequest> requests) {
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
