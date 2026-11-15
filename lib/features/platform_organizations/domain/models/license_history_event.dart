/// Kind of change recorded in an organization's license history.
enum LicenseEventType {
  assigned,
  planChanged,
  commercialTermsModified,
  renewed,
}

/// One append-only history row. Plan name, level and limits come from the
/// live plan row, as the server returns them; dates and prices are the values
/// at the time of the event.
class LicenseHistoryEvent {
  const LicenseHistoryEvent({
    required this.id,
    required this.eventType,
    required this.eventAt,
    required this.planId,
    required this.planCode,
    required this.planName,
    required this.planLevel,
    required this.maxStores,
    required this.maxUsers,
    required this.startDate,
    required this.expiryDate,
    required this.negotiatedPrice,
    required this.maintenancePrice,
  });

  final String id;
  final LicenseEventType eventType;

  /// Instant of the event (timestamp, not a calendar date).
  final DateTime eventAt;
  final String planId;
  final String planCode;
  final String planName;
  final int planLevel;
  final int maxStores;
  final int maxUsers;
  final DateTime startDate;
  final DateTime expiryDate;
  final double negotiatedPrice;
  final double maintenancePrice;
}
