/// Daily attendance breakdown for organization or branch dashboards.
///
/// There is no shift schedule or leave data in the backend yet, so real
/// repositories derive [totalScheduled] from the expected headcount, [absent]
/// from "no check-in recorded" and leave [onLeave] null (not tracked).
class AttendanceSummary {
  final int present;
  final int late;
  final int absent;

  /// Employees on approved leave, or null when leave is not tracked.
  final int? onLeave;
  final int totalScheduled;

  const AttendanceSummary({
    required this.present,
    required this.late,
    required this.absent,
    this.onLeave,
    required this.totalScheduled,
  });

  /// Builds a summary from check-in counts and the expected headcount.
  factory AttendanceSummary.fromCheckIns({
    required int checkedIn,
    required int late,
    required int expectedHeadcount,
  }) {
    final onTime = (checkedIn - late).clamp(0, checkedIn);
    final total = expectedHeadcount < checkedIn ? checkedIn : expectedHeadcount;
    return AttendanceSummary(
      present: onTime,
      late: late,
      absent: total - checkedIn,
      totalScheduled: total,
    );
  }

  double get attendanceRate {
    if (totalScheduled == 0) return 0.0;
    return (present / totalScheduled).clamp(0.0, 1.0);
  }

  int get attendancePercentage => (attendanceRate * 100).round();

  /// Headcount used as the denominator for distribution shares.
  int get distributionTotal {
    if (totalScheduled > 0) return totalScheduled;
    return present + late + absent + (onLeave ?? 0);
  }

  double _share(int count) {
    final total = distributionTotal;
    return total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
  }

  double get presentShare => _share(present);
  double get lateShare => _share(late);
  double get absentShare => _share(absent);
}
