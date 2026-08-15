import 'dart:async';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_session.dart';

abstract interface class AuthRemoteDataSource {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<OtpSession> sendOtp({required String phoneNumber, int? resendToken});
  Future<AuthUser> verifyOtp(
      {required String verificationId, required String smsCode});
  Future<AuthUser> signInWithGoogle();
  Future<void> signOut();
}

/// InMemoryAuthDataSource provides an isolated, reliable authentication simulation
/// with strict validation conforming to production Firebase Authentication behavior.
class InMemoryAuthDataSource implements AuthRemoteDataSource {
  InMemoryAuthDataSource({AuthUser? initialUser}) {
    _currentUser = initialUser;
    _controller.add(initialUser);
  }

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  final Map<String, _PendingVerification> _pendingVerifications = {};

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<OtpSession> sendOtp(
      {required String phoneNumber, int? resendToken}) async {
    // Basic network simulation delay
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (phoneNumber.replaceAll(RegExp(r'\D'), '').length < 10) {
      throw AuthException.invalidPhoneNumber();
    }

    final verificationId = 'ver_${DateTime.now().millisecondsSinceEpoch}';
    final token = resendToken ?? DateTime.now().millisecondsSinceEpoch;

    // For testing and predictable demo verification, we generate a known code
    _pendingVerifications[verificationId] = _PendingVerification(
      phoneNumber: phoneNumber,
      code: '123456',
      createdAt: DateTime.now(),
    );

    return OtpSession(
      verificationId: verificationId,
      phoneNumber: phoneNumber,
      resendToken: token,
      createdAt: DateTime.now(),
      timeoutSeconds: 60,
    );
  }

  @override
  Future<AuthUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final pending = _pendingVerifications[verificationId];
    if (pending == null) {
      throw AuthException.otpExpired();
    }

    if (DateTime.now().difference(pending.createdAt).inSeconds > 60) {
      _pendingVerifications.remove(verificationId);
      throw AuthException.otpExpired();
    }

    if (smsCode != pending.code) {
      throw AuthException.invalidOtp();
    }

    _pendingVerifications.remove(verificationId);

    final user = AuthUser(
      uid: 'user_${pending.phoneNumber.replaceAll(RegExp(r'\D'), '')}',
      phoneNumber: pending.phoneNumber,
      displayName: 'WorkAxis User',
    );

    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    const user = AuthUser(
      uid: 'google_user_001',
      email: 'alex.morgan@workaxis.io',
      phoneNumber: '+15551234567',
      displayName: 'Alex Morgan',
      photoUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=128',
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}

class _PendingVerification {
  _PendingVerification({
    required this.phoneNumber,
    required this.code,
    required this.createdAt,
  });

  final String phoneNumber;
  final String code;
  final DateTime createdAt;
}
