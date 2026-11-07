import 'package:intl/intl.dart';

/// Canonical, cached date/time/number formatters.
///
/// `DateFormat`/`NumberFormat` construction is expensive; creating them per row
/// or per build is wasteful. Always use these helpers instead.
abstract final class AppFormatters {
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _date = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTime = DateFormat('MMM d, yyyy h:mm a');
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final NumberFormat _compact = NumberFormat.decimalPattern();

  /// Canonical time-of-day format, e.g. `9:05 AM`. Returns [placeholder] for null.
  static String formatTime(DateTime? value, {String placeholder = '--'}) =>
      value == null ? placeholder : _time.format(value);

  /// e.g. `Nov 7, 2026`.
  static String formatDate(DateTime? value, {String placeholder = '--'}) =>
      value == null ? placeholder : _date.format(value);

  /// e.g. `Nov 7`.
  static String formatShortDate(DateTime? value, {String placeholder = '--'}) =>
      value == null ? placeholder : _shortDate.format(value);

  /// e.g. `Nov 7, 2026 9:05 AM`.
  static String formatDateTime(DateTime? value, {String placeholder = '--'}) =>
      value == null ? placeholder : _dateTime.format(value);

  /// Indian Rupee currency without decimals, e.g. `₹1,25,000`.
  static String formatCurrencyInr(num value) => _inr.format(value);

  /// Grouped integer/decimal number, e.g. `12,345`.
  static String formatNumber(num value) => _compact.format(value);
}
