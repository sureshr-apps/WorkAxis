import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';
import 'package:workaxis/features/authentication/domain/services/google_auth_service.dart';

/// Test and mock implementation of [GoogleAuthService] for fast, deterministic unit and widget tests.
class InMemoryGoogleAuthService implements GoogleAuthService {
  InMemoryGoogleAuthService({
    this.mockUser = const AuthUser(
      uid: 'google_user_001',
      email: 'alex.morgan@workaxis.io',
      phoneNumber: '+15551234567',
      displayName: 'Alex Morgan',
      photoUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=128',
    ),
    this.shouldCancel = false,
    this.exceptionToThrow,
  });

  AuthUser? mockUser;
  bool shouldCancel;
  Exception? exceptionToThrow;
  AuthUser? _currentUser;

  @override
  Future<AuthUser?> signIn() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (shouldCancel) {
      return null;
    }
    _currentUser = mockUser;
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<bool> isSignedIn() async {
    return _currentUser != null;
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    return _currentUser;
  }
}
