import 'package:intl/intl.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_license_rules.dart';

/// Text for the license tab. Calendar dates are shown as `yyyy-MM-dd`, event
/// times in India time, and money in INR. Day counts are relative to the
/// business date, for display only; enforcement uses the server status.
abstract final class LicenseFormatters {
  static final DateFormat _eventTime = DateFormat('dd MMM yyyy, hh:mm a');

  /// e.g. `2026-11-07`.
  static String date(DateTime calendarDate) =>
      CalendarDate.format(calendarDate);

  /// e.g. `2026-11-07 to 2027-11-06`.
  static String period(DateTime start, DateTime expiry) =>
      '${date(start)} to ${date(expiry)}';

  /// Event instant in India time, e.g. `07 Nov 2026, 10:45 AM IST`.
  static String eventTime(DateTime instant) {
    final india = instant.toUtc().add(kBusinessUtcOffset);
    return '${_eventTime.format(india)} IST';
  }

  /// e.g. `₹1,20,000`.
  static String money(num value) => AppFormatters.formatCurrencyInr(value);

  /// Plan limits, e.g. `12,345`.
  static String count(int value) => AppFormatters.formatNumber(value);

  /// Contextual line under the license summary, measured from [today] (the
  /// business date). Examples: "Scheduled to activate in 3 days (2026-11-10)",
  /// "Expired 5 days ago on 2026-11-02", "Expires in 10 days (2026-11-17) -
  /// Renewal recommended".
  static String termNote(OrganizationLicense license, DateTime today) {
    final untilStart = CalendarDate.daysBetween(today, license.startDate);
    if (untilStart > 0) {
      return 'Scheduled to activate in ${_days(untilStart)} '
          '(${date(license.startDate)})';
    }
    final expiry = date(license.expiryDate);
    final untilExpiry = CalendarDate.daysBetween(today, license.expiryDate);
    if (untilExpiry < 0) {
      return 'Expired ${_days(-untilExpiry)} ago on $expiry';
    }
    final recommended =
        untilExpiry <= OrganizationLicenseRules.renewalRecommendedWithinDays;
    if (untilExpiry == 0) {
      return recommended
          ? 'Expires today ($expiry) - Renewal recommended'
          : 'Expires today ($expiry)';
    }
    if (recommended) {
      return 'Expires in ${_days(untilExpiry)} ($expiry) - Renewal recommended';
    }
    return 'Expires in ${_days(untilExpiry)} ($expiry)';
  }

  static String _days(int count) => '$count ${count == 1 ? 'day' : 'days'}';
}
