import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_session.dart';
import 'package:workaxis/features/authentication/domain/repositories/auth_repository.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthOtpSent extends AuthState {
  const AuthOtpSent({
    required this.session,
    this.isResending = false,
  });

  final OtpSession session;
  final bool isResending;

  @override
  List<Object?> get props => [session, isResending];
}

final class AuthAuthenticating extends AuthState {
  const AuthAuthenticating({this.message = 'Verifying...'});
  final String message;

  @override
  List<Object?> get props => [message];
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

final class AuthError extends AuthState {
  const AuthError(this.exception, {this.previousSession});
  final AppException exception;
  final OtpSession? previousSession;

  @override
  List<Object?> get props => [exception, previousSession];
}

class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository {
    _init();
  }

  final AuthRepository _authRepository;
  StreamSubscription<AuthUser?>? _authSubscription;

  AuthState _state = const AuthInitial();
  AuthState get state => _state;

  AuthUser? get currentUser => _authRepository.currentUser;
  bool get isAuthenticated => _state is AuthAuthenticated;

  void _init() {
    final current = _authRepository.currentUser;
    if (current != null) {
      _state = AuthAuthenticated(current);
    }
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _state = AuthAuthenticated(user);
      } else {
        if (_state is! AuthInitial && _state is! AuthOtpSent) {
          _state = const AuthInitial();
        }
      }
      notifyListeners();
    });
  }

  Future<void> sendOtp({
    required String phoneNumber,
    int? resendToken,
  }) async {
    _state = const AuthAuthenticating(message: 'Sending code...');
    notifyListeners();

    try {
      final session = await _authRepository.sendOtp(
        phoneNumber: phoneNumber,
        resendToken: resendToken,
      );
      _state = AuthOtpSent(session: session);
      notifyListeners();
    } on AppException catch (e) {
      _state = AuthError(e);
      notifyListeners();
    } catch (e) {
      _state = AuthError(AuthException.failed(e.toString()));
      notifyListeners();
    }
  }

  Future<void> resendOtp({required OtpSession currentSession}) async {
    _state = AuthOtpSent(session: currentSession, isResending: true);
    notifyListeners();

    try {
      final newSession = await _authRepository.sendOtp(
        phoneNumber: currentSession.phoneNumber,
        resendToken: currentSession.resendToken,
      );
      _state = AuthOtpSent(session: newSession, isResending: false);
      notifyListeners();
    } on AppException catch (e) {
      _state = AuthError(e, previousSession: currentSession);
      notifyListeners();
    } catch (e) {
      _state = AuthError(
        AuthException.failed(e.toString()),
        previousSession: currentSession,
      );
      notifyListeners();
    }
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final prevSession =
        _state is AuthOtpSent ? (_state as AuthOtpSent).session : null;
    _state = const AuthAuthenticating(message: 'Verifying code...');
    notifyListeners();

    try {
      final user = await _authRepository.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      _state = AuthAuthenticated(user);
      notifyListeners();
    } on AppException catch (e) {
      _state = AuthError(e, previousSession: prevSession);
      notifyListeners();
    } catch (e) {
      _state = AuthError(
        AuthException.invalidOtp(),
        previousSession: prevSession,
      );
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _state = const AuthAuthenticating(message: 'Connecting to Google...');
    notifyListeners();

    try {
      final user = await _authRepository.signInWithGoogle();
      _state = AuthAuthenticated(user);
      notifyListeners();
    } on AppException catch (e) {
      _state = AuthError(e);
      notifyListeners();
    } catch (e) {
      _state = AuthError(AuthException.failed(e.toString()));
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _state = const AuthAuthenticating(message: 'Signing out...');
    notifyListeners();
    await _authRepository.signOut();
    _state = const AuthInitial();
    notifyListeners();
  }

  void resetToInitial() {
    _state = const AuthInitial();
    notifyListeners();
  }

  void returnToOtp(OtpSession session) {
    _state = AuthOtpSent(session: session);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
