import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// Maps the pure domain [AttendanceStatus] to display text and chip styling.
extension AttendanceStatusPresentation on AttendanceStatus {
  String get label => switch (this) {
    AttendanceStatus.present => 'Present',
    AttendanceStatus.late => 'Late',
    AttendanceStatus.absent => 'Absent',
    AttendanceStatus.incomplete => 'Incomplete',
  };

  StatusType get chipType => switch (this) {
    AttendanceStatus.present => StatusType.active,
    AttendanceStatus.late => StatusType.pending,
    AttendanceStatus.absent => StatusType.urgent,
    AttendanceStatus.incomplete => StatusType.urgent,
  };
}

/// Display helpers for [AttendanceEntry].
extension AttendanceEntryPresentation on AttendanceEntry {
  bool get needsReview => reviewStatus == AttendanceReviewStatus.needsReview;

  String get sourceLabel => kioskEntry ? 'Kiosk' : 'Mobile';

  /// Up to two uppercase initials; `?` for an empty name (never throws).
  String get initials {
    final parts = employeeName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length < 2 ? word.length : 2).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
