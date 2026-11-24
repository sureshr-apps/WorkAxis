import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// One employee's attendance for one business date, with the underlying
/// branch-specific punch sessions preserved for the details view.
class AttendanceDaySummary {
  const AttendanceDaySummary._({
    required this.employeeId,
    required this.employeeName,
    required this.workDate,
    required this.sessions,
  });

  final String employeeId;
  final String employeeName;
  final DateTime workDate;
  final List<AttendanceEntry> sessions;

  String get id =>
      '$employeeId-${workDate.year.toString().padLeft(4, '0')}-'
      '${workDate.month.toString().padLeft(2, '0')}-'
      '${workDate.day.toString().padLeft(2, '0')}';

  List<String> get branchIds => sessions
      .map((session) => session.branchId)
      .where((branchId) => branchId.isNotEmpty)
      .toSet()
      .toList(growable: false);

  DateTime? get firstCheckIn => _earliest(
    sessions.map((session) => session.checkInAt).whereType<DateTime>(),
  );

  /// A day is still in progress while any session is open. A session the
  /// system closed without a check-out is not open.
  DateTime? get lastCheckOut {
    if (sessions.any((session) => session.isOpen)) {
      return null;
    }
    return _latest(
      sessions.map((session) => session.checkOutAt).whereType<DateTime>(),
    );
  }

  int get needsReviewCount => sessions
      .where(
        (session) => session.reviewStatus == AttendanceReviewStatus.needsReview,
      )
      .length;

  AttendanceStatus get status {
    if (sessions.any(
      (session) => session.status == AttendanceStatus.incomplete,
    )) {
      return AttendanceStatus.incomplete;
    }
    if (sessions.any((session) => session.status == AttendanceStatus.late)) {
      return AttendanceStatus.late;
    }
    if (sessions.every(
      (session) => session.status == AttendanceStatus.absent,
    )) {
      return AttendanceStatus.absent;
    }
    return AttendanceStatus.present;
  }

  static List<AttendanceDaySummary> fromEntries(
    Iterable<AttendanceEntry> entries,
  ) {
    final grouped = <String, List<AttendanceEntry>>{};
    for (final entry in entries) {
      final key = _key(entry.employeeId, entry.workDate);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    final summaries = grouped.values.map((sessions) {
      sessions.sort(_compareSessionTime);
      final first = sessions.first;
      return AttendanceDaySummary._(
        employeeId: first.employeeId,
        employeeName: first.employeeName,
        workDate: DateTime(
          first.workDate.year,
          first.workDate.month,
          first.workDate.day,
        ),
        sessions: List.unmodifiable(sessions),
      );
    }).toList();
    summaries.sort((a, b) {
      final aTime = a.firstCheckIn ?? a.workDate;
      final bTime = b.firstCheckIn ?? b.workDate;
      return aTime.compareTo(bTime);
    });
    return List.unmodifiable(summaries);
  }

  static String _key(String employeeId, DateTime date) =>
      '$employeeId-${date.year}-${date.month}-${date.day}';

  static int _compareSessionTime(AttendanceEntry a, AttendanceEntry b) =>
      (a.checkInAt ?? a.workDate).compareTo(b.checkInAt ?? b.workDate);

  static DateTime? _earliest(Iterable<DateTime> values) {
    DateTime? result;
    for (final value in values) {
      if (result == null || value.isBefore(result)) result = value;
    }
    return result;
  }

  static DateTime? _latest(Iterable<DateTime> values) {
    DateTime? result;
    for (final value in values) {
      if (result == null || value.isAfter(result)) result = value;
    }
    return result;
  }
}
