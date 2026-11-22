/// One day's attendance times. Kept so elapsed time and progress can be
/// recomputed as the clock moves on, instead of being fixed when loaded.
class AttendanceSession {
  const AttendanceSession({
    required this.checkIn,
    required this.standardSeconds,
    this.checkOut,
    this.breaks = const [],
    this.workedBeforeSeconds = 0,
  });

  final DateTime checkIn;
  final DateTime? checkOut;
  final List<AttendanceBreak> breaks;

  /// Length of a standard working day, in seconds.
  final int standardSeconds;

  /// Work already completed in earlier same-day branch sessions.
  final int workedBeforeSeconds;

  /// Whether the employee is still checked in (not yet checked out).
  bool get isRunning => checkOut == null;

  /// Time worked up to [now]: check-in to check-out (or [now]) minus breaks.
  Duration workedAt(DateTime now) {
    final end = checkOut ?? now;
    var total =
        end.difference(checkIn) + Duration(seconds: workedBeforeSeconds);
    for (final b in breaks) {
      total -= (b.end ?? end).difference(b.start);
    }
    return total.isNegative ? Duration.zero : total;
  }

  /// Share of the standard day worked by [now], between 0 and 1.
  double progressAt(DateTime now) {
    if (standardSeconds <= 0) return 0;
    return (workedAt(now).inSeconds / standardSeconds).clamp(0.0, 1.0);
  }

  /// `5h 42m`, with minutes always two digits.
  static String formatDuration(Duration d) {
    final minutes = d.inMinutes % 60;
    return '${d.inHours}h ${minutes.toString().padLeft(2, '0')}m';
  }
}

/// A break from [start] to [end]; [end] is null while the break is open.
class AttendanceBreak {
  const AttendanceBreak({required this.start, this.end});

  final DateTime start;
  final DateTime? end;
}
