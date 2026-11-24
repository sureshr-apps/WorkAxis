import 'package:flutter/material.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/time/business_time.dart';

/// Shift and check-out times shown in the business timezone (Asia/Kolkata),
/// never the device zone, so a night shift reads the same on every device.
abstract final class BusinessTimeText {
  /// The instant's wall-clock fields in the business timezone.
  static DateTime wallClock(DateTime instant) =>
      instant.toUtc().add(kBusinessUtcOffset);

  /// The instant at [date] (business calendar date) and [time] in the
  /// business timezone.
  static DateTime instantAt(DateTime date, TimeOfDay time) =>
      BusinessTime.startOfDay(date)
          .add(Duration(hours: time.hour, minutes: time.minute));

  /// e.g. `9:00 PM`.
  static String time(DateTime instant) =>
      AppFormatters.formatTime(wallClock(instant));

  /// e.g. `Nov 7`.
  static String shortDate(DateTime instant) =>
      AppFormatters.formatShortDate(wallClock(instant));

  /// e.g. `Nov 8, 5:10 AM`.
  static String shortDateTime(DateTime instant) =>
      '${shortDate(instant)}, ${time(instant)}';

  /// e.g. `Shift 9:00 PM – 5:00 AM`, or null when the window is unknown.
  static String? shiftWindow(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    return 'Shift ${time(start)} – ${time(end)}';
  }
}
