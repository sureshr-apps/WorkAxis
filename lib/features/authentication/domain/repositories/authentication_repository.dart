import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/authentication_result.dart';

/// Permanent application contract for authentication workflows.
///
/// Designed to remain stable across both initial mock implementations
/// and future Firebase Authentication / server-side implementations.
abstract interface class AuthenticationRepository {
  /// Signs in a user using an account identifier (username, email, or phone)
  /// and password.
  Future<AuthenticationResult> signIn({
    required String identifier,
    required String password,
  });

  /// Terminates the current authenticated session.
  Future<void> signOut();

  /// Changes the signed-in user's own password.
  ///
  /// Implementations must verify [currentPassword] before applying
  /// [newPassword] and throw an `AppException` (with a safe `userMessage`)
  /// when the change cannot be completed.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Retrieves the currently cached/signed-in user, or null if unauthenticated.
  Future<AppUser?> getCurrentUser();

  /// Stream of authentication state changes.
  Stream<AppUser?> authStateChanges();
}
