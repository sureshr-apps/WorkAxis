import 'package:google_sign_in/google_sign_in.dart';
import 'package:workaxis/core/config/app_config.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';
import 'package:workaxis/features/authentication/domain/services/google_auth_service.dart';

/// Production implementation of [GoogleAuthService] using the official [google_sign_in] package.
class GoogleSignInServiceImpl implements GoogleAuthService {
  GoogleSignInServiceImpl({
    GoogleSignIn? googleSignIn,
    GoogleAuthConfig config = const GoogleAuthConfig(),
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: config.serverClientId.isNotEmpty
                  ? config.serverClientId
                  : null,
              clientId: config.clientId.isNotEmpty ? config.clientId : null,
              scopes: config.scopes,
            );

  final GoogleSignIn _googleSignIn;

  @override
  Future<AuthUser?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled the sign-in flow (e.g. dismissed the Google prompt)
        return null;
      }

      return AuthUser(
        uid: 'google_${account.id}',
        email: account.email,
        displayName: account.displayName ?? 'Google User',
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException(
        message: 'Google Sign-In failed: $e',
        code: 'google-sign-in-failed',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  @override
  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;
    return AuthUser(
      uid: 'google_${account.id}',
      email: account.email,
      displayName: account.displayName ?? 'Google User',
      photoUrl: account.photoUrl,
    );
  }
}
