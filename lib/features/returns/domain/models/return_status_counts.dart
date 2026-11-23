import 'package:workaxis/features/returns/domain/models/return_item.dart';

/// Which returns of the active branch a Branch Manager is looking at. Other
/// roles have a single queue (their own returns, or the organization's).
enum ReturnQueue {
  /// Returns the manager filed themself.
  mine,

  /// Returns filed by others in the branch (the review queue).
  others,
}

/// Server-side status totals for one returns scope. They ignore the status
/// filter and search text, and cover every page, not just the loaded ones.
class ReturnStatusCounts {
  const ReturnStatusCounts({
    this.pending = 0,
    this.approved = 0,
    this.rejected = 0,
  });

  static const empty = ReturnStatusCounts();

  final int pending;
  final int approved;
  final int rejected;

  int get total => pending + approved + rejected;

  int of(ReturnStatus status) => switch (status) {
    ReturnStatus.pending => pending,
    ReturnStatus.approved => approved,
    ReturnStatus.rejected => rejected,
  };

  /// Moves one return from [from] to [to] (a review decision), or adds one
  /// when [from] is null (a new submission).
  ReturnStatusCounts moved({ReturnStatus? from, required ReturnStatus to}) {
    int delta(ReturnStatus status) =>
        (status == to ? 1 : 0) - (status == from ? 1 : 0);
    return ReturnStatusCounts(
      pending: pending + delta(ReturnStatus.pending),
      approved: approved + delta(ReturnStatus.approved),
      rejected: rejected + delta(ReturnStatus.rejected),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReturnStatusCounts &&
      other.pending == pending &&
      other.approved == approved &&
      other.rejected == rejected;

  @override
  int get hashCode => Object.hash(pending, approved, rejected);

  @override
  String toString() =>
      'ReturnStatusCounts(pending: $pending, approved: $approved, rejected: $rejected)';
}
