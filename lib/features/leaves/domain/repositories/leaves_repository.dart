import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

abstract interface class LeavesRepository {
  Future<List<LeaveRequest>> getLeaveRequests({
    required UserAccessContext access,
    String? activeBranchId,
  });

  Future<LeaveRequest> submitLeaveRequest({
    required UserAccessContext access,
    String? branchId,
    String? activeBranchId,
    required LeaveRequestDraft draft,
  });

  Future<LeaveRequest> updatePendingLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveRequestDraft draft,
  });

  Future<LeaveRequest> reviewLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveStatus decision,
    String? reviewerNotes,
  });
}
