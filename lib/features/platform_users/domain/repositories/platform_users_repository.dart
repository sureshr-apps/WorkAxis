import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';

/// Platform Owner operations for Platform Administrator accounts.
abstract interface class PlatformUsersRepository {
  Future<List<PlatformAdministrator>> getAdministrators({
    String? query,
    AccountStatus? status,
  });

  Future<PlatformAdministrator?> getAdministratorById(String id);

  /// Creates an administrator identity using an ephemeral initial password.
  /// Implementations must hand the credential to a trusted auth provider and
  /// must never persist it with the profile record.
  Future<PlatformAdministrator> createAdministrator({
    required PlatformAdministrator administrator,
    required String initialPassword,
  });

  Future<PlatformAdministrator> updateAdministrator(
    PlatformAdministrator administrator,
  );

  /// Suspends or restores sign-in access without deleting the profile.
  Future<PlatformAdministrator> updateAdministratorStatus(
    String id,
    AccountStatus status,
  );
}
