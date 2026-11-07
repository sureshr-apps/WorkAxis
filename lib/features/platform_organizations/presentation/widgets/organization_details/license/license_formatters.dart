import 'package:intl/intl.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';

/// Cached formatters and labels for the license tab. Building a `DateFormat`
/// or `NumberFormat` is expensive, so none is created while building.
abstract final class LicenseFormatters {
  static final DateFormat _date = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final NumberFormat _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// e.g. `2026-11-07`.
  static String date(DateTime value) => _date.format(value);

  /// e.g. `07 Nov 2026, 10:45 AM`.
  static String dateTime(DateTime value) => _dateTime.format(value);

  /// e.g. `₹40,000.00`.
  static String money(num value) => _money.format(value);

  /// "Expires in N days (date)", "Expires today (date)" or
  /// "Expired N days ago (date)", relative to [today].
  static String expiryLabel(
    OrganizationLicenseDetails license,
    DateTime today,
  ) {
    final days = license.daysRemaining(today);
    final when = date(license.agreementExpiry);
    if (days > 0) {
      return 'Expires in $days ${days == 1 ? 'day' : 'days'} ($when)';
    }
    if (days == 0) return 'Expires today ($when)';
    final ago = -days;
    return 'Expired $ago ${ago == 1 ? 'day' : 'days'} ago ($when)';
  }
}
