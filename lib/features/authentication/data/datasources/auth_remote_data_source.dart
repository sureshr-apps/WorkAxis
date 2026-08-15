import 'dart:async';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/data/services/in_memory_google_auth_service.dart';
import 'package:workaxis/features/authentication/data/services/in_memory_otp_service.dart';
import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_session.dart';
import 'package:workaxis/features/authentication/domain/services/google_auth_service.dart';
import 'package:workaxis/features/authentication/domain/services/otp_service.dart';

abstract interface class AuthRemoteDataSource {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<OtpSession> sendOtp({
    required String phoneNumber,
    OtpChannel channel = OtpChannel.sms,
    int? resendToken,
  });
  Future<AuthUser> verifyOtp({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  });
  Future<AuthUser> signInWithGoogle();
  Future<void> signOut();
}

/// [OtpServiceAuthDataSource] implements [AuthRemoteDataSource] powered by pluggable [OtpService] and [GoogleAuthService].
class OtpServiceAuthDataSource implements AuthRemoteDataSource {
  OtpServiceAuthDataSource({
    required OtpService otpService,
    GoogleAuthService? googleAuthService,
    AuthUser? initialUser,
  })  : _otpService = otpService,
        _googleAuthService = googleAuthService ?? InMemoryGoogleAuthService(),
        _currentUser = initialUser {
    _controller.add(initialUser);
  }

  final OtpService _otpService;
  final GoogleAuthService _googleAuthService;
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  final Map<String, _SessionMetadata> _sessions = {};

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<OtpSession> sendOtp({
    required String phoneNumber,
    OtpChannel channel = OtpChannel.sms,
    int? resendToken,
  }) async {
    final result = await _otpService.sendOtp(
      phoneNumber: phoneNumber,
      channel: channel,
    );

    final session = OtpSession(
      verificationId: result.verificationId,
      phoneNumber: phoneNumber,
      channel: channel,
      resendToken: resendToken ?? DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
      timeoutSeconds: result.expiresInSeconds,
    );

    _sessions[result.verificationId] = _SessionMetadata(
      phoneNumber: phoneNumber,
      channel: channel,
    );

    return session;
  }

  @override
  Future<AuthUser> verifyOtp({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  }) async {
    final sessionMeta = _sessions[verificationId];
    final targetPhone = phoneNumber ?? sessionMeta?.phoneNumber;

    if (targetPhone == null) {
      throw const AuthException(
        message: 'Invalid session or phone number. Please request a new code.',
        code: 'invalid-session',
      );
    }

    final isValid = await _otpService.verifyOtp(
      phoneNumber: targetPhone,
      otp: smsCode,
      verificationId: verificationId,
    );

    if (!isValid) {
      throw AuthException.invalidOtp();
    }

    _sessions.remove(verificationId);

    final user = AuthUser(
      uid: 'user_${targetPhone.replaceAll(RegExp(r'\D'), '')}',
      phoneNumber: targetPhone,
      displayName: 'WorkAxis User',
    );

    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = await _googleAuthService.signIn();
    if (user == null) {
      throw const AuthException(
        message: 'Google Sign-In was cancelled.',
        code: 'google-sign-in-cancelled',
      );
    }
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _googleAuthService.signOut();
    _currentUser = null;
    _controller.add(null);
  }
}

/// Backwards-compatible convenience alias default for development and testing.
class InMemoryAuthDataSource extends OtpServiceAuthDataSource {
  InMemoryAuthDataSource({
    OtpService? otpService,
    GoogleAuthService? googleAuthService,
    super.initialUser,
  }) : super(
          otpService: otpService ?? InMemoryOtpService(),
          googleAuthService: googleAuthService ?? InMemoryGoogleAuthService(),
        );
}

class _SessionMetadata {
  const _SessionMetadata({
    required this.phoneNumber,
    required this.channel,
  });

  final String phoneNumber;
  final OtpChannel channel;
}
