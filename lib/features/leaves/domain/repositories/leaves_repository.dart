import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_status_counts.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';

abstract interface class LeavesRepository {
  /// One page of [queue], optionally limited to [status], in server order
  /// (pending first, then start date ascending).
  Future<PageResult<LeaveRequest>> getLeaveRequestsPage({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
    LeaveStatus? status,
    int offset = 0,
    int limit = defaultPageSize,
  });

  /// Per-status totals for the whole of [queue] (ignores any status filter).
  Future<LeaveStatusCounts> getLeaveStatusCounts({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
  });

  /// The organization's active leave types, in display order.
  Future<List<LeaveTypeOption>> getLeaveTypes({
    required UserAccessContext access,
  });

  /// How the applicant's own draft would be paid if approved now.
  /// [editingRequestId] is the pending request being edited, so it is not
  /// counted against its own allowance.
  Future<LeavePreview> previewLeaveDraft({
    required UserAccessContext access,
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    String? editingRequestId,
  });

  /// How [request] would be paid if a reviewer approved it now. Needs the
  /// same scope as reviewing it.
  Future<LeavePreview> previewLeaveReview({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
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
