import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// Client-side checks for a check-out correction request. They mirror the
/// server's `RequestCheckoutCorrection` rules so the employee gets clear
/// feedback before submitting; the server still decides.
abstract final class CheckoutCorrectionValidator {
  static const int maxReasonLength = 500;

  /// A corrected check-out may be at most this long after check-in.
  static const Duration maxSessionLength = Duration(hours: 24);

  /// Why [checkOutAt] cannot be requested for [entry] at [now], or null.
  /// [formatTime] renders instants for the messages (business timezone).
  static String? checkOutError({
    required AttendanceEntry entry,
    required DateTime? checkOutAt,
    required DateTime now,
    required String Function(DateTime instant) formatTime,
  }) {
    if (checkOutAt == null) return 'Choose when you actually checked out.';
    final checkIn = entry.checkInAt;
    if (checkIn == null) return 'This session has no check-in to correct.';
    if (!checkOutAt.isAfter(checkIn)) {
      return 'The check-out must be after your check-in at ${formatTime(checkIn)}.';
    }
    final lastBreak = _lastBreakMoment(entry);
    if (lastBreak != null && !checkOutAt.isAfter(lastBreak)) {
      return 'The check-out must be after your last break (${formatTime(lastBreak)}).';
    }
    if (checkOutAt.isAfter(now)) {
      return 'The check-out cannot be in the future.';
    }
    final recorded = entry.checkOutAt;
    if (recorded != null && !checkOutAt.isBefore(recorded)) {
      return 'The check-out must be earlier than the recorded check-out at ${formatTime(recorded)}.';
    }
    if (checkOutAt.difference(checkIn) > maxSessionLength) {
      return 'The check-out must be within 24 hours of your check-in.';
    }
    return null;
  }

  /// Why [reason] cannot be sent, or null.
  static String? reasonError(String reason) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return 'Explain why the check-out needs correcting.';
    if (trimmed.length > maxReasonLength) {
      return 'Use $maxReasonLength characters or fewer.';
    }
    return null;
  }

  /// The latest break moment: its end, or its start while it was left open.
  static DateTime? _lastBreakMoment(AttendanceEntry entry) {
    DateTime? latest;
    for (final pause in entry.breaks) {
      final moment = pause.endAt ?? pause.startAt;
      if (latest == null || moment.isAfter(latest)) latest = moment;
    }
    return latest;
  }
}
