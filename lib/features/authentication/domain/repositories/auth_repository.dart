import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_session.dart';

/// Abstract contract for authentication operations.
abstract interface class AuthRepository {
  /// Stream emitting authenticated user state updates.
  Stream<AuthUser?> get authStateChanges;

  /// Current authenticated user identity.
  AuthUser? get currentUser;

  /// Initiates Phone Number verification and returns an OTP session.
  Future<OtpSession> sendOtp({
    required String phoneNumber,
    int? resendToken,
  });

  /// Verifies the entered 6-digit OTP and authenticates the user.
  Future<AuthUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Authenticates using Google Sign-In (optional/platform configurable).
  Future<AuthUser> signInWithGoogle();

  /// Signs out the user and clears authentication session.
  Future<void> signOut();
}
