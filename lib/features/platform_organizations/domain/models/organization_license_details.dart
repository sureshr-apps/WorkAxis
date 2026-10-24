/// Mockable organization license and commercial agreement details.
///
/// License data belongs to the organization feature contract so a future data
/// source can replace the mock without changing the presentation layer.
class OrganizationLicenseDetails {
  final String planName;
  final String status;
  final int level;
  final String agreementId;
  final DateTime agreementStart;
  final DateTime agreementExpiry;
  final int maximumStores;
  final int maximumUsers;
  final double negotiatedPrice;
  final double annualMaintenancePrice;
  final String currencyCode;
  final List<LicenseHistoryEntry> history;

  const OrganizationLicenseDetails({
    required this.planName,
    required this.status,
    required this.level,
    required this.agreementId,
    required this.agreementStart,
    required this.agreementExpiry,
    required this.maximumStores,
    required this.maximumUsers,
    required this.negotiatedPrice,
    required this.annualMaintenancePrice,
    this.currencyCode = 'INR',
    this.history = const [],
  });

  int daysRemaining(DateTime today) {
    final expiry = DateTime(
      agreementExpiry.year,
      agreementExpiry.month,
      agreementExpiry.day,
    );
    final current = DateTime(today.year, today.month, today.day);
    return expiry.difference(current).inDays;
  }
}

class LicenseHistoryEntry {
  final String event;
  final DateTime occurredAt;
  final String planName;
  final int level;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int stores;
  final int users;
  final double negotiatedPrice;
  final double annualMaintenancePrice;

  const LicenseHistoryEntry({
    required this.event,
    required this.occurredAt,
    required this.planName,
    required this.level,
    required this.periodStart,
    required this.periodEnd,
    required this.stores,
    required this.users,
    required this.negotiatedPrice,
    required this.annualMaintenancePrice,
  });
}
