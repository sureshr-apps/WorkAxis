import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';

/// Abstract contract for Google Authentication.
abstract interface class GoogleAuthService {
  /// Prompts the user to sign in with their Google account.
  /// Returns [AuthUser] if successful, or `null` if the user cancelled.
  Future<AuthUser?> signIn();

  /// Signs the user out of their Google session.
  Future<void> signOut();

  /// Checks if a user is currently signed in with Google.
  Future<bool> isSignedIn();

  /// Gets the currently signed-in Google user, or `null` if not signed in.
  Future<AuthUser?> getCurrentUser();
}
