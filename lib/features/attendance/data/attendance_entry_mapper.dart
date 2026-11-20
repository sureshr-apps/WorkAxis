import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// Maps `attendance_entries` documents to [AttendanceEntry].
abstract final class AttendanceEntryMapper {
  static AttendanceEntry fromData(String docId, Map<String, dynamic> data) {
    return AttendanceEntry(
      id: docId,
      organizationId: data['organizationId'] as String? ?? '',
      branchId: data['branchId'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String? ?? 'Unknown employee',
      workDate: _workDate(data),
      status: _status(data['status'] as String?),
      reviewStatus: _reviewStatus(data['reviewStatus'] as String?),
      checkInAt: instant(data['checkInAt']),
      checkOutAt: instant(data['checkOutAt']),
      checkInSelfiePath: data['checkInSelfiePath'] as String?,
      checkOutSelfiePath: data['checkOutSelfiePath'] as String?,
      breaks: _breaks(data['breaks']),
      note: data['note'] as String?,
      kioskEntry: data['kioskEntry'] as bool? ?? false,
    );
  }

  /// The business calendar date: `workDateString` wins; otherwise the stored
  /// instant converted to the business timezone (never the device zone).
  static DateTime _workDate(Map<String, dynamic> data) {
    final key = data['workDateString'];
    if (key is String) {
      final parsed = DateTime.tryParse(key);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    final stored =
        instant(data['workDate']) ??
        instant(data['createdAt']) ??
        instant(data['checkInAt']);
    return stored != null
        ? BusinessTime.dateOf(stored)
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Converts a Firestore timestamp (or ISO string) to a [DateTime].
  static DateTime? instant(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<AttendanceBreakRecord> _breaks(Object? value) {
    if (value is! List) return const [];
    final breaks = <AttendanceBreakRecord>[];
    for (final item in value.whereType<Map>()) {
      final startAt = instant(item['startAt']);
      if (startAt == null) continue;
      breaks.add(
        AttendanceBreakRecord(
          startAt: startAt,
          endAt: instant(item['endAt']),
          startSelfiePath: item['startSelfiePath'] as String?,
          endSelfiePath: item['endSelfiePath'] as String?,
        ),
      );
    }
    return List.unmodifiable(breaks);
  }

  /// Unknown values are surfaced as `incomplete` (needs attention) rather than
  /// silently reported as `present`.
  static AttendanceStatus _status(String? raw) {
    for (final s in AttendanceStatus.values) {
      if (s.name.toLowerCase() == (raw ?? '').toLowerCase()) return s;
    }
    return AttendanceStatus.incomplete;
  }

  static AttendanceReviewStatus _reviewStatus(String? raw) {
    for (final s in AttendanceReviewStatus.values) {
      if (s.name.toLowerCase() == (raw ?? 'none').toLowerCase()) return s;
    }
    return AttendanceReviewStatus.none;
  }
}
