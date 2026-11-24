/// Operational policy for one customer organization.
///
/// Stored in Firestore `organization_settings/{organizationId}`.
enum PayCalculationBasis {
  hours('hours'),
  workdays('workdays');

  const PayCalculationBasis(this.wireValue);
  final String wireValue;

  static PayCalculationBasis fromWire(Object? value) => values.firstWhere(
    (basis) => basis.wireValue == value,
    orElse: () => hours,
  );
}

class OrganizationSettings {
  const OrganizationSettings({
    required this.geofenceRadiusMeters,
    required this.gracePeriodMinutes,
    required this.allowBreaks,
    required this.requireGeolocation,
    required this.dailyDigest,
    required this.returnAlerts,
    this.requireEmployeeAssetAcknowledgement = true,
    this.requireAttendanceSelfie = true,
    this.requireBranchManagerAttendance = false,
    this.payCalculationBasis = PayCalculationBasis.hours,
    this.overtimeEnabled = false,
    this.earlyCheckInMinutes = 120,
    this.checkoutReminderMinutes = 30,
    this.overtimeReviewMinutes = 240,
    this.maxSessionHours = 16,
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
    requireEmployeeAssetAcknowledgement: true,
    requireAttendanceSelfie: true,
    requireBranchManagerAttendance: false,
    payCalculationBasis: PayCalculationBasis.hours,
    overtimeEnabled: false,
  );

  /// Geofence radius used when a branch has no positive radius configured.
  final int geofenceRadiusMeters;

  /// Minutes after shift start before a check-in counts as late.
  final int gracePeriodMinutes;
  final bool allowBreaks;
  final bool requireGeolocation;
  final bool dailyDigest;
  final bool returnAlerts;
  final bool requireEmployeeAssetAcknowledgement;
  final bool requireAttendanceSelfie;
  final bool requireBranchManagerAttendance;
  final PayCalculationBasis payCalculationBasis;
  final bool overtimeEnabled;

  /// How long before a shift starts a check-in still counts toward it.
  final int earlyCheckInMinutes;

  /// How long after the shift ends the employee is reminded to check out.
  final int checkoutReminderMinutes;

  /// Overtime allowed after the shift ends before an open session is
  /// flagged for the manager (a later check-out is still recorded).
  final int overtimeReviewMinutes;

  /// After this long an open session is closed as a missing check-out.
  final int maxSessionHours;
  final String? operationsEmail;
  final String? emergencyPhone;

  OrganizationSettings copyWith({
    int? geofenceRadiusMeters,
    int? gracePeriodMinutes,
    bool? allowBreaks,
    bool? requireGeolocation,
    bool? dailyDigest,
    bool? returnAlerts,
    bool? requireEmployeeAssetAcknowledgement,
    bool? requireAttendanceSelfie,
    bool? requireBranchManagerAttendance,
    PayCalculationBasis? payCalculationBasis,
    bool? overtimeEnabled,
    int? earlyCheckInMinutes,
    int? checkoutReminderMinutes,
    int? overtimeReviewMinutes,
    int? maxSessionHours,
    String? operationsEmail,
    String? emergencyPhone,
  }) => OrganizationSettings(
    geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
    gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
    allowBreaks: allowBreaks ?? this.allowBreaks,
    requireGeolocation: requireGeolocation ?? this.requireGeolocation,
    dailyDigest: dailyDigest ?? this.dailyDigest,
    returnAlerts: returnAlerts ?? this.returnAlerts,
    requireEmployeeAssetAcknowledgement:
        requireEmployeeAssetAcknowledgement ??
        this.requireEmployeeAssetAcknowledgement,
    requireAttendanceSelfie:
        requireAttendanceSelfie ?? this.requireAttendanceSelfie,
    requireBranchManagerAttendance:
        requireBranchManagerAttendance ?? this.requireBranchManagerAttendance,
    payCalculationBasis: payCalculationBasis ?? this.payCalculationBasis,
    overtimeEnabled: overtimeEnabled ?? this.overtimeEnabled,
    earlyCheckInMinutes: earlyCheckInMinutes ?? this.earlyCheckInMinutes,
    checkoutReminderMinutes:
        checkoutReminderMinutes ?? this.checkoutReminderMinutes,
    overtimeReviewMinutes: overtimeReviewMinutes ?? this.overtimeReviewMinutes,
    maxSessionHours: maxSessionHours ?? this.maxSessionHours,
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
      other.requireEmployeeAssetAcknowledgement ==
          requireEmployeeAssetAcknowledgement &&
      other.requireAttendanceSelfie == requireAttendanceSelfie &&
      other.requireBranchManagerAttendance == requireBranchManagerAttendance &&
      other.payCalculationBasis == payCalculationBasis &&
      other.overtimeEnabled == overtimeEnabled &&
      other.earlyCheckInMinutes == earlyCheckInMinutes &&
      other.checkoutReminderMinutes == checkoutReminderMinutes &&
      other.overtimeReviewMinutes == overtimeReviewMinutes &&
      other.maxSessionHours == maxSessionHours &&
      other.operationsEmail == operationsEmail &&
      other.emergencyPhone == emergencyPhone;

  @override
  int get hashCode => Object.hashAll([
    geofenceRadiusMeters,
    gracePeriodMinutes,
    allowBreaks,
    requireGeolocation,
    dailyDigest,
    returnAlerts,
    requireEmployeeAssetAcknowledgement,
    requireAttendanceSelfie,
    requireBranchManagerAttendance,
    payCalculationBasis,
    overtimeEnabled,
    earlyCheckInMinutes,
    checkoutReminderMinutes,
    overtimeReviewMinutes,
    maxSessionHours,
    operationsEmail,
    emergencyPhone,
  ]);
}
