import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/settings/domain/models/organization_settings.dart';
import 'package:workaxis/features/settings/domain/models/platform_settings.dart';
import 'package:workaxis/features/settings/domain/repositories/settings_repository.dart';
import 'package:workaxis/features/settings/domain/services/settings_authorization.dart';
import 'package:workaxis/features/settings/domain/validators/settings_validators.dart';

/// Production [SettingsRepository] on Cloud Firestore:
/// `organization_settings/{organizationId}` and `platform_settings/global`.
///
/// Settings are low-volume documents keyed by their owner, which is why they
/// live in Firestore rather than SQL. Writes stamp `updatedAt` with the
/// server time and `updatedBy` with the caller's uid; the matching security
/// rules are listed in `docs/architecture.md`.
class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  static const String organizationCollection = 'organization_settings';
  static const String platformCollection = 'platform_settings';
  static const String platformDocumentId = 'global';

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _organizationDoc(String orgId) =>
      _firestore.collection(organizationCollection).doc(orgId);

  DocumentReference<Map<String, dynamic>> get _platformDoc =>
      _firestore.collection(platformCollection).doc(platformDocumentId);

  @override
  Future<OrganizationSettings> getOrganizationSettings({
    required UserAccessContext access,
  }) async {
    try {
      final orgId = SettingsAuthorization.organizationId(access);
      final snapshot = await _organizationDoc(orgId).get();
      final data = snapshot.data();
      return data == null
          ? OrganizationSettings.defaults
          : _toOrganization(data);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<OrganizationSettings> saveOrganizationSettings({
    required UserAccessContext access,
    required OrganizationSettings settings,
  }) async {
    try {
      final orgId = SettingsAuthorization.organizationId(access);
      SettingsAuthorization.requireValid(
        SettingsValidators.organization(settings),
      );
      await _organizationDoc(orgId).set({
        'organizationId': orgId,
        'geofenceRadiusMeters': settings.geofenceRadiusMeters,
        'gracePeriodMinutes': settings.gracePeriodMinutes,
        'allowBreaks': settings.allowBreaks,
        'requireGeolocation': settings.requireGeolocation,
        'dailyDigest': settings.dailyDigest,
        'returnAlerts': settings.returnAlerts,
        'operationsEmail': _blankToNull(settings.operationsEmail),
        'emergencyPhone': _blankToNull(settings.emergencyPhone),
        'updatedBy': access.user.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return settings;
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<PlatformSettings> getPlatformSettings({
    required UserAccessContext access,
  }) async {
    try {
      SettingsAuthorization.requirePlatformReader(access);
      final data = (await _platformDoc.get()).data();
      return data == null ? PlatformSettings.defaults : _toPlatform(data);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<PlatformSettings> savePlatformSettings({
    required UserAccessContext access,
    required PlatformSettings settings,
  }) async {
    try {
      SettingsAuthorization.requirePlatformWriter(access);
      SettingsAuthorization.requireValid(SettingsValidators.platform(settings));
      await _platformDoc.set({
        'sessionTimeoutMinutes': settings.sessionTimeoutMinutes,
        'maxLoginAttempts': settings.maxLoginAttempts,
        'maintenanceMode': settings.maintenanceMode,
        'enforceStrongPasswords': settings.enforceStrongPasswords,
        'updatedBy': access.user.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return settings;
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  /// Missing fields fall back to the documented defaults, so a partially
  /// written document never produces a half-empty policy.
  OrganizationSettings _toOrganization(Map<String, dynamic> data) {
    const d = OrganizationSettings.defaults;
    return OrganizationSettings(
      geofenceRadiusMeters:
          (data['geofenceRadiusMeters'] as num?)?.toInt() ??
          d.geofenceRadiusMeters,
      gracePeriodMinutes:
          (data['gracePeriodMinutes'] as num?)?.toInt() ?? d.gracePeriodMinutes,
      allowBreaks: data['allowBreaks'] as bool? ?? d.allowBreaks,
      requireGeolocation:
          data['requireGeolocation'] as bool? ?? d.requireGeolocation,
      dailyDigest: data['dailyDigest'] as bool? ?? d.dailyDigest,
      returnAlerts: data['returnAlerts'] as bool? ?? d.returnAlerts,
      operationsEmail: data['operationsEmail'] as String?,
      emergencyPhone: data['emergencyPhone'] as String?,
    );
  }

  PlatformSettings _toPlatform(Map<String, dynamic> data) {
    const d = PlatformSettings.defaults;
    return PlatformSettings(
      sessionTimeoutMinutes:
          (data['sessionTimeoutMinutes'] as num?)?.toInt() ??
          d.sessionTimeoutMinutes,
      maxLoginAttempts:
          (data['maxLoginAttempts'] as num?)?.toInt() ?? d.maxLoginAttempts,
      maintenanceMode: data['maintenanceMode'] as bool? ?? d.maintenanceMode,
      enforceStrongPasswords:
          data['enforceStrongPasswords'] as bool? ?? d.enforceStrongPasswords,
    );
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
