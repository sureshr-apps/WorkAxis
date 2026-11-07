/// Operational policy for one customer organization.
///
/// Stored in Firestore `organization_settings/{organizationId}`.
class OrganizationSettings {
  const OrganizationSettings({
    required this.geofenceRadiusMeters,
    required this.gracePeriodMinutes,
    required this.allowBreaks,
    required this.requireGeolocation,
    required this.dailyDigest,
    required this.returnAlerts,
    this.operationsEmail,
    this.emergencyPhone,
  });

  /// Policy applied until an administrator saves the organization's own.
  static const OrganizationSettings defaults = OrganizationSettings(
    geofenceRadiusMeters: 150,
    gracePeriodMinutes: 15,
    allowBreaks: true,
    requireGeolocation: true,
    dailyDigest: true,
    returnAlerts: true,
  );

  /// Default geofence radius for newly created branches.
  final int geofenceRadiusMeters;

  /// Minutes after shift start before a check-in counts as late.
  final int gracePeriodMinutes;
  final bool allowBreaks;
  final bool requireGeolocation;
  final bool dailyDigest;
  final bool returnAlerts;
  final String? operationsEmail;
  final String? emergencyPhone;

  OrganizationSettings copyWith({
    int? geofenceRadiusMeters,
    int? gracePeriodMinutes,
    bool? allowBreaks,
    bool? requireGeolocation,
    bool? dailyDigest,
    bool? returnAlerts,
    String? operationsEmail,
    String? emergencyPhone,
  }) => OrganizationSettings(
    geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
    gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
    allowBreaks: allowBreaks ?? this.allowBreaks,
    requireGeolocation: requireGeolocation ?? this.requireGeolocation,
    dailyDigest: dailyDigest ?? this.dailyDigest,
    returnAlerts: returnAlerts ?? this.returnAlerts,
    operationsEmail: operationsEmail ?? this.operationsEmail,
    emergencyPhone: emergencyPhone ?? this.emergencyPhone,
  );

  @override
  bool operator ==(Object other) =>
      other is OrganizationSettings &&
      other.geofenceRadiusMeters == geofenceRadiusMeters &&
      other.gracePeriodMinutes == gracePeriodMinutes &&
      other.allowBreaks == allowBreaks &&
      other.requireGeolocation == requireGeolocation &&
      other.dailyDigest == dailyDigest &&
      other.returnAlerts == returnAlerts &&
      other.operationsEmail == operationsEmail &&
      other.emergencyPhone == emergencyPhone;

  @override
  int get hashCode => Object.hash(
    geofenceRadiusMeters,
    gracePeriodMinutes,
    allowBreaks,
    requireGeolocation,
    dailyDigest,
    returnAlerts,
    operationsEmail,
    emergencyPhone,
  );
}
