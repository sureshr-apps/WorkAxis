/// Typed daily attendance breakdown for organization or branch dashboards.
class AttendanceSummary {
  final int present;
  final int late;
  final int absent;
  final int onLeave;
  final int totalScheduled;

  const AttendanceSummary({
    required this.present,
    required this.late,
    required this.absent,
    required this.onLeave,
    required this.totalScheduled,
  });

  double get attendanceRate {
    if (totalScheduled == 0) return 0.0;
    return (present / totalScheduled).clamp(0.0, 1.0);
  }

  int get attendancePercentage => (attendanceRate * 100).round();
}
