import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/settings/domain/models/organization_settings.dart';
import 'package:workaxis/features/settings/domain/models/platform_settings.dart';

/// Settings fields that can fail validation.
enum SettingsField {
  geofenceRadius,
  gracePeriod,
  operationsEmail,
  emergencyPhone,
  sessionTimeout,
  maxLoginAttempts,
}

/// Validation of settings values. Ranges match the server-side branch
/// geofence limits (10-5000 m) and sensible security bounds.
abstract final class SettingsValidators {
  static const int minGeofenceRadiusMeters = 10;
  static const int maxGeofenceRadiusMeters = 5000;
  static const int minGracePeriodMinutes = 0;
  static const int maxGracePeriodMinutes = 120;
  static const int minSessionTimeoutMinutes = 5;
  static const int maxSessionTimeoutMinutes = 1440;
  static const int minLoginAttempts = 3;
  static const int maxLoginAttempts = 10;

  static Map<SettingsField, String> organization(OrganizationSettings s) {
    final errors = <SettingsField, String>{};
    _range(
      errors,
      SettingsField.geofenceRadius,
      s.geofenceRadiusMeters,
      minGeofenceRadiusMeters,
      maxGeofenceRadiusMeters,
      'Geofence radius',
      'm',
    );
    _range(
      errors,
      SettingsField.gracePeriod,
      s.gracePeriodMinutes,
      minGracePeriodMinutes,
      maxGracePeriodMinutes,
      'Grace period',
      'min',
    );
    final emailError = ContactValidators.optionalEmail(s.operationsEmail);
    if (emailError != null) {
      errors[SettingsField.operationsEmail] = emailError;
    }
    final phoneError = ContactValidators.optionalPhone(s.emergencyPhone);
    if (phoneError != null) {
      errors[SettingsField.emergencyPhone] = phoneError;
    }
    return errors;
  }

  static Map<SettingsField, String> platform(PlatformSettings s) {
    final errors = <SettingsField, String>{};
    _range(
      errors,
      SettingsField.sessionTimeout,
      s.sessionTimeoutMinutes,
      minSessionTimeoutMinutes,
      maxSessionTimeoutMinutes,
      'Session timeout',
      'min',
    );
    _range(
      errors,
      SettingsField.maxLoginAttempts,
      s.maxLoginAttempts,
      minLoginAttempts,
      maxLoginAttempts,
      'Failed login attempts',
      '',
    );
    return errors;
  }

  static void _range(
    Map<SettingsField, String> errors,
    SettingsField field,
    int value,
    int min,
    int max,
    String label,
    String unit,
  ) {
    if (value < min || value > max) {
      final suffix = unit.isEmpty ? '' : ' $unit';
      errors[field] = '$label must be between $min and $max$suffix.';
    }
  }
}
