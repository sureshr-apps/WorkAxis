import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/authentication_result.dart';
import 'package:workaxis/features/authentication/domain/repositories/authentication_repository.dart';

/// Presentation controller managing user authentication state.
class AuthController extends ChangeNotifier with SafeNotifier {
  AuthController({required this.authRepository, this.onSessionLost});

  final AuthenticationRepository authRepository;

  /// Invoked when the identity provider ends the session behind our back
  /// (token revoked, account disabled, signed out elsewhere). The session
  /// controller uses it to wipe session-scoped state.
  VoidCallback? onSessionLost;

  AppUser? _currentUser;
  bool _isInitializing = false;
  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _isSigningOut = false;
  String? _errorMessage;
  String? _passwordChangeError;
  StreamSubscription<AppUser?>? _authSubscription;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// True while [init] is restoring a previous session. The router shows a
  /// splash instead of redirecting during this window.
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  bool get isChangingPassword => _isChangingPassword;
  String? get errorMessage => _errorMessage;
  String? get passwordChangeError => _passwordChangeError;

  /// Restores a previously established session and starts monitoring the
  /// identity provider. Must complete before the first route redirect.
  Future<void> init() async {
    if (_authSubscription != null || _isInitializing) return;
    _isInitializing = true;
    notifyListeners();

    try {
      final restored = await authRepository.getCurrentUser();
      if (!isDisposed &&
          restored != null &&
          restored.status == AccountStatus.active) {
        _currentUser = restored;
      }
    } catch (e, st) {
      if (isDisposed) return;
      _currentUser = null;
      _errorMessage = mapBackendError(e, st).userMessage;
    } finally {
      if (!isDisposed) {
        _isInitializing = false;
        _authSubscription = authRepository.authStateChanges().listen(
          _onAuthStateChanged,
          onError: _onAuthStreamError,
        );
        notifyListeners();
      }
    }
  }

  void _onAuthStateChanged(AppUser? user) {
    final current = _currentUser;
    // Sign-in completes through [signIn] (which enforces all checks); a
    // non-null event while signed out is therefore ignored.
    if (current == null || _isLoading || _isSigningOut) return;

    if (user == null || user.status != AccountStatus.active) {
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
      onSessionLost?.call();
      return;
    }
    if (user.id == current.id) {
      _currentUser = user;
      notifyListeners();
    }
  }

  void _onAuthStreamError(Object error, StackTrace stackTrace) {
    // A transient failure must not be mistaken for a sign-out: keep the
    // session and record the problem for diagnostics.
    developer.log(
      'Auth state stream error',
      name: 'workaxis.auth',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Attempts to authenticate the user using any valid login alias.
  Future<bool> signIn({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await authRepository.signIn(
        identifier: identifier,
        password: password,
      );

      switch (result) {
        case AuthenticationSuccess(:final user):
          _currentUser = user;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        case AuthenticationFailure(:final errorMessage):
          _currentUser = null;
          _isLoading = false;
          _errorMessage = errorMessage;
          notifyListeners();
          return false;
      }
    } catch (e, st) {
      _currentUser = null;
      _isLoading = false;
      _errorMessage = mapBackendError(e, st).userMessage;
      notifyListeners();
      return false;
    }
  }

  /// Changes the signed-in user's own password. Returns `true` on success;
  /// on failure [passwordChangeError] holds a safe, user-facing message.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isChangingPassword = true;
    _passwordChangeError = null;
    notifyListeners();
    try {
      await authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e, st) {
      _passwordChangeError = mapBackendError(e, st).userMessage;
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  /// Terminates the current session.
  ///
  /// The local user is cleared synchronously (before the first `await`) so the
  /// router leaves protected routes immediately; the identity provider call
  /// follows and its failure is logged rather than thrown. Callers that also
  /// need to wipe session-scoped state should use `SessionController.signOut`.
  Future<void> signOut() async {
    _isSigningOut = true;
    _currentUser = null;
    _errorMessage = null;
    _passwordChangeError = null;
    notifyListeners();

    try {
      await authRepository.signOut();
    } catch (e, st) {
      developer.log(
        'Sign-out failed at the identity provider',
        name: 'workaxis.auth',
        level: 1000,
        error: e,
        stackTrace: st,
      );
    } finally {
      _isSigningOut = false;
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearPasswordChangeError() {
    if (_passwordChangeError != null) {
      _passwordChangeError = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
