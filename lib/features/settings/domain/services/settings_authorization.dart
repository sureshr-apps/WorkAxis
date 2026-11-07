import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/settings/domain/validators/settings_validators.dart';

/// Authorization and validation rules shared by every [SettingsRepository]
/// implementation. The backend rules remain authoritative.
abstract final class SettingsAuthorization {
  /// Organization id for organization settings; Organization Admins only.
  static String organizationId(UserAccessContext access) {
    final orgId = access.organization?.id;
    if (access.user.role != UserRole.orgAdmin ||
        orgId == null ||
        orgId.isEmpty) {
      throw const AccessDeniedException(
        'Organization settings require an Organization Admin session.',
      );
    }
    return orgId;
  }

  /// Platform roles may read platform settings.
  static void requirePlatformReader(UserAccessContext access) {
    if (!access.user.role.isPlatformLevel) {
      throw const AccessDeniedException(
        'Platform settings require a platform user.',
      );
    }
  }

  /// Only the Platform Owner may change platform settings.
  static void requirePlatformWriter(UserAccessContext access) {
    if (access.user.role != UserRole.platformOwner) {
      throw const AccessDeniedException(
        'Only the Platform Owner may change platform settings.',
        'Only the Platform Owner can change platform settings.',
      );
    }
  }

  /// Throws if [errors] is not empty, carrying the first message.
  static void requireValid(Map<SettingsField, String> errors) {
    if (errors.isEmpty) return;
    throw DatabaseException(
      'Invalid settings: ${errors.keys.map((k) => k.name).join(', ')}',
      userMessage: errors.values.first,
    );
  }
}
