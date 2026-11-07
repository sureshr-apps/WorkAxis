import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/settings/domain/models/organization_settings.dart';
import 'package:workaxis/features/settings/domain/models/platform_settings.dart';
import 'package:workaxis/features/settings/domain/repositories/settings_repository.dart';
import 'package:workaxis/features/settings/domain/services/settings_authorization.dart';
import 'package:workaxis/features/settings/domain/validators/settings_validators.dart';

/// In-memory [SettingsRepository] with the same authorization and validation
/// as the real one. Organization settings are kept per organization id.
class MockSettingsRepository implements SettingsRepository {
  MockSettingsRepository({
    this.delay = const Duration(milliseconds: 150),
    PlatformSettings? initialPlatform,
  }) : _platform = initialPlatform ?? PlatformSettings.defaults;

  final Duration delay;
  final Map<String, OrganizationSettings> _organizations = {};
  PlatformSettings _platform;

  Future<void> _latency() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<OrganizationSettings> getOrganizationSettings({
    required UserAccessContext access,
  }) async {
    final orgId = SettingsAuthorization.organizationId(access);
    await _latency();
    return _organizations[orgId] ?? OrganizationSettings.defaults;
  }

  @override
  Future<OrganizationSettings> saveOrganizationSettings({
    required UserAccessContext access,
    required OrganizationSettings settings,
  }) async {
    final orgId = SettingsAuthorization.organizationId(access);
    SettingsAuthorization.requireValid(
      SettingsValidators.organization(settings),
    );
    await _latency();
    _organizations[orgId] = settings;
    return settings;
  }

  @override
  Future<PlatformSettings> getPlatformSettings({
    required UserAccessContext access,
  }) async {
    SettingsAuthorization.requirePlatformReader(access);
    await _latency();
    return _platform;
  }

  @override
  Future<PlatformSettings> savePlatformSettings({
    required UserAccessContext access,
    required PlatformSettings settings,
  }) async {
    SettingsAuthorization.requirePlatformWriter(access);
    SettingsAuthorization.requireValid(SettingsValidators.platform(settings));
    await _latency();
    _platform = settings;
    return settings;
  }
}
