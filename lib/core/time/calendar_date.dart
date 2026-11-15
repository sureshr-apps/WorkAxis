import 'package:workaxis/core/time/business_time.dart';

/// Calendar-date arithmetic for `yyyy-MM-dd` values such as license terms.
///
/// A calendar date has no time zone, so every value is held as UTC midnight and
/// day arithmetic runs in UTC. A daylight-saving shift on the device therefore
/// can never move a date by one day. Use [BusinessTime] to find "today" in the
/// business time zone.
abstract final class CalendarDate {
  static final RegExp _datePrefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

  /// Parses `yyyy-MM-dd` (anything after the date part is ignored). Returns
  /// null for other text, including impossible dates such as `2026-02-30`.
  static DateTime? tryParse(String value) {
    final match = _datePrefix.firstMatch(value.trim());
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final date = DateTime.utc(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// Like [tryParse] but throws a [FormatException] for invalid input.
  static DateTime parse(String value) {
    final date = tryParse(value);
    if (date == null) throw FormatException('Not a yyyy-MM-dd date: $value');
    return date;
  }

  /// The calendar date of [value]'s year, month and day fields. Time and zone
  /// are dropped.
  static DateTime of(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  /// `yyyy-MM-dd` for the calendar date of [date].
  static String format(DateTime date) => BusinessTime.keyOfDate(date);

  static DateTime addDays(DateTime date, int days) =>
      DateTime.utc(date.year, date.month, date.day + days);

  /// Same month and day one or more years later. February 29 rolls over to
  /// March 1 in a non-leap year, as Dart's date normalisation does.
  static DateTime addYears(DateTime date, int years) =>
      DateTime.utc(date.year + years, date.month, date.day);

  /// Whole calendar days from [from] to [to]; negative when [to] is earlier.
  static int daysBetween(DateTime from, DateTime to) =>
      of(to).difference(of(from)).inDays;
}
