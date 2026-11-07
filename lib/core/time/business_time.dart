import 'package:workaxis/core/time/clock.dart';

/// Business timezone for every business-day key (matches `BUSINESS_TIMEZONE`
/// in `functions/src/config.ts` and `docs/backend-api.md`).
const String kBusinessTimeZone = 'Asia/Kolkata';

/// Fixed offset of [kBusinessTimeZone] (UTC+05:30, no daylight saving).
const Duration kBusinessUtcOffset = Duration(hours: 5, minutes: 30);

/// Business-day helpers. Business keys (`workDateString`) must never be
/// derived from the device-local date, so everything here converts through UTC.
abstract final class BusinessTime {
  /// The business calendar date (time fields zeroed) that [instant] falls on.
  static DateTime dateOf(DateTime instant) {
    final shifted = instant.toUtc().add(kBusinessUtcOffset);
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  /// Today's business date according to [now].
  static DateTime today(Now now) => dateOf(now());

  /// `yyyy-MM-dd` for the business day containing [instant].
  static String keyOfInstant(DateTime instant) => keyOfDate(dateOf(instant));

  /// `yyyy-MM-dd` for a calendar [date] (its year/month/day fields are the
  /// business date, as picked in a date picker).
  static String keyOfDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$mm-$dd';
  }

  /// The instant at which business [date] starts (00:00 in the business zone).
  static DateTime startOfDay(DateTime date) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).subtract(kBusinessUtcOffset);
}
