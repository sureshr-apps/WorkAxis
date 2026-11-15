import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Business rules for organization licenses that the client applies to forms
/// and plan lists. The server enforces the same rules and remains the authority.
abstract final class OrganizationLicenseRules {
  /// A term ending within this many days is flagged "Renewal recommended".
  static const int renewalRecommendedWithinDays = 30;

  /// Parses a whole-rupee amount. Returns null when blank, not a whole number,
  /// or negative.
  static double? parseWholeRupees(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final value = int.tryParse(trimmed);
    if (value == null || value < 0) return null;
    return value.toDouble();
  }

  /// Error text for a price field, or null when [raw] is valid.
  static String? priceError(String raw, {required String fieldName}) =>
      parseWholeRupees(raw) == null
      ? 'Enter a valid $fieldName (whole rupees, 0 or more).'
      : null;

  /// The expiry must fall strictly after the start.
  static String? termError(DateTime startDate, DateTime expiryDate) =>
      expiryDate.isAfter(startDate)
      ? null
      : 'Expiry date must be after the start date.';

  /// Renewal rules: the new term starts after the current expiry and ends
  /// after its own start.
  static String? renewalTermError({
    required DateTime currentExpiry,
    required DateTime newStart,
    required DateTime newExpiry,
  }) {
    if (!newStart.isAfter(currentExpiry)) {
      return 'The new start date must be after the current expiry date '
          '(${CalendarDate.format(currentExpiry)}).';
    }
    return termError(newStart, newExpiry);
  }

  /// Plans that may be assigned: active plans, lowest level first.
  static List<LicensePlan> assignablePlans(List<LicensePlan> plans) =>
      _sortedByLevel(plans.where((plan) => plan.status == PlanStatus.active));

  /// Plans an organization may move to: active and strictly higher level.
  static List<LicensePlan> changeTargets(
    List<LicensePlan> plans,
    int currentLevel,
  ) => _sortedByLevel(
    plans.where(
      (plan) => plan.status == PlanStatus.active && plan.level > currentLevel,
    ),
  );

  /// Plans a renewal may use: active and same or higher level (no downgrades).
  static List<LicensePlan> renewalPlans(
    List<LicensePlan> plans,
    int currentLevel,
  ) => _sortedByLevel(
    plans.where(
      (plan) => plan.status == PlanStatus.active && plan.level >= currentLevel,
    ),
  );

  /// Default renewal start: the day after the current expiry.
  static DateTime defaultRenewalStart(DateTime currentExpiry) =>
      CalendarDate.addDays(currentExpiry, 1);

  /// Default expiry for a new term: one year after its start.
  static DateTime defaultTermExpiry(DateTime start) =>
      CalendarDate.addYears(start, 1);

  /// Whether a renewal starting on [newStart] continues a term that is running
  /// today. The server then keeps the current start date and extends the
  /// expiry instead.
  static bool continuesRunningTerm(
    OrganizationLicense license,
    DateTime newStart,
  ) {
    final runningStatus =
        license.status == OrganizationLicenseStatus.active ||
        license.status == OrganizationLicenseStatus.expiringSoon;
    return runningStatus &&
        license.plan.isActive &&
        CalendarDate.of(newStart) ==
            CalendarDate.addDays(license.expiryDate, 1);
  }

  /// History ordered with the newest event first.
  static List<LicenseHistoryEvent> newestFirst(
    Iterable<LicenseHistoryEvent> events,
  ) => [...events]..sort((a, b) => b.eventAt.compareTo(a.eventAt));

  static List<LicensePlan> _sortedByLevel(Iterable<LicensePlan> plans) =>
      [...plans]..sort((a, b) => a.level.compareTo(b.level));
}
