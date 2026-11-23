import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

/// Per-status totals for one leave queue, computed by the server over the
/// whole queue (independent of the status filter and loaded pages).
class LeaveStatusCounts {
  const LeaveStatusCounts({
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  static const LeaveStatusCounts zero = LeaveStatusCounts(
    pending: 0,
    approved: 0,
    rejected: 0,
  );

  final int pending;
  final int approved;
  final int rejected;

  int get total => pending + approved + rejected;

  int of(LeaveStatus status) => switch (status) {
    LeaveStatus.pending => pending,
    LeaveStatus.approved => approved,
    LeaveStatus.rejected => rejected,
  };

  /// Counts after one request in [status] was added.
  LeaveStatusCounts added(LeaveStatus status) => _shift(status, 1);

  /// Counts after one request moved from [from] to [to].
  LeaveStatusCounts moved(LeaveStatus from, LeaveStatus to) =>
      from == to ? this : _shift(from, -1)._shift(to, 1);

  LeaveStatusCounts _shift(LeaveStatus status, int delta) {
    int next(int value) => value + delta < 0 ? 0 : value + delta;
    return LeaveStatusCounts(
      pending: status == LeaveStatus.pending ? next(pending) : pending,
      approved: status == LeaveStatus.approved ? next(approved) : approved,
      rejected: status == LeaveStatus.rejected ? next(rejected) : rejected,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LeaveStatusCounts &&
      other.pending == pending &&
      other.approved == approved &&
      other.rejected == rejected;

  @override
  int get hashCode => Object.hash(pending, approved, rejected);

  @override
  String toString() =>
      'LeaveStatusCounts(pending: $pending, approved: $approved, '
      'rejected: $rejected)';
}
