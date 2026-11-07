import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';

/// Platform Owner operations for Platform Administrator accounts.
///
/// Reads are paginated with server-side search and status filters; writes go
/// through trusted callables (no client writes to identity stores).
abstract interface class PlatformUsersRepository {
  Future<PageResult<PlatformAdministrator>> getAdministratorsPage({
    String? query,
    AccountStatus? status,
    int offset = 0,
    int limit = defaultPageSize,
  });

  /// Number of administrators with [status] (all when null), for summaries.
  Future<int> countAdministrators({AccountStatus? status});

  Future<PlatformAdministrator?> getAdministratorById(String id);

  /// Creates an administrator sign-in identity. The password is handed to the
  /// trusted function and never stored by the client. Returns the saved
  /// account with its server-assigned id.
  Future<PlatformAdministrator> createAdministrator({
    required PlatformAdministrator administrator,
    required String initialPassword,
  });

  /// Updates name, email and phone. Status changes use
  /// [updateAdministratorStatus].
  Future<PlatformAdministrator> updateAdministrator(
    PlatformAdministrator administrator,
  );

  /// Suspends or restores sign-in access without deleting the profile.
  Future<PlatformAdministrator> updateAdministratorStatus(
    String id,
    AccountStatus status,
  );

  Future<void> resetAdministratorPassword({
    required String id,
    required String newPassword,
  });
}
