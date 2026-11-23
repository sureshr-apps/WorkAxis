import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

/// The order the server lists leave requests in: pending first, then by
/// start date ascending, then newest created first, then id descending.
int compareLeaveRequests(LeaveRequest a, LeaveRequest b) {
  final pending = _pendingRank(a).compareTo(_pendingRank(b));
  if (pending != 0) return pending;
  final start = a.startDate.compareTo(b.startDate);
  if (start != 0) return start;
  final created = _createdMillis(b).compareTo(_createdMillis(a));
  if (created != 0) return created;
  return b.id.compareTo(a.id);
}

int _pendingRank(LeaveRequest request) =>
    request.status == LeaveStatus.pending ? 0 : 1;

int _createdMillis(LeaveRequest request) =>
    request.createdAt?.millisecondsSinceEpoch ?? 0;
