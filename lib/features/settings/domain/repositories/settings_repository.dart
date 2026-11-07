import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/settings/domain/models/organization_settings.dart';
import 'package:workaxis/features/settings/domain/models/platform_settings.dart';

/// Organization and platform settings.
///
/// Organization settings: readable by the organization's admins (and
/// platform roles), writable by Organization Admins of that organization.
/// Platform settings: readable by platform roles, writable by the Platform
/// Owner. Missing documents resolve to the model `defaults`.
abstract interface class SettingsRepository {
  Future<OrganizationSettings> getOrganizationSettings({
    required UserAccessContext access,
  });

  Future<OrganizationSettings> saveOrganizationSettings({
    required UserAccessContext access,
    required OrganizationSettings settings,
  });

  Future<PlatformSettings> getPlatformSettings({
    required UserAccessContext access,
  });

  Future<PlatformSettings> savePlatformSettings({
    required UserAccessContext access,
    required PlatformSettings settings,
  });
}
