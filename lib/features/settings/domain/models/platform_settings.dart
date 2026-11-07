/// Platform-wide security and availability policy.
///
/// Stored in Firestore `platform_settings/global`.
class PlatformSettings {
  const PlatformSettings({
    required this.sessionTimeoutMinutes,
    required this.maxLoginAttempts,
    required this.maintenanceMode,
    required this.enforceStrongPasswords,
  });

  /// Policy applied until the platform owner saves one.
  static const PlatformSettings defaults = PlatformSettings(
    sessionTimeoutMinutes: 60,
    maxLoginAttempts: 5,
    maintenanceMode: false,
    enforceStrongPasswords: true,
  );

  final int sessionTimeoutMinutes;
  final int maxLoginAttempts;
  final bool maintenanceMode;
  final bool enforceStrongPasswords;

  PlatformSettings copyWith({
    int? sessionTimeoutMinutes,
    int? maxLoginAttempts,
    bool? maintenanceMode,
    bool? enforceStrongPasswords,
  }) => PlatformSettings(
    sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
    maxLoginAttempts: maxLoginAttempts ?? this.maxLoginAttempts,
    maintenanceMode: maintenanceMode ?? this.maintenanceMode,
    enforceStrongPasswords:
        enforceStrongPasswords ?? this.enforceStrongPasswords,
  );

  @override
  bool operator ==(Object other) =>
      other is PlatformSettings &&
      other.sessionTimeoutMinutes == sessionTimeoutMinutes &&
      other.maxLoginAttempts == maxLoginAttempts &&
      other.maintenanceMode == maintenanceMode &&
      other.enforceStrongPasswords == enforceStrongPasswords;

  @override
  int get hashCode => Object.hash(
    sessionTimeoutMinutes,
    maxLoginAttempts,
    maintenanceMode,
    enforceStrongPasswords,
  );
}
