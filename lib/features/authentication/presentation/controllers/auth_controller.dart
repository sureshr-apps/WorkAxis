import 'package:flutter/foundation.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/authentication_result.dart';
import 'package:workaxis/features/authentication/domain/repositories/authentication_repository.dart';

/// Presentation controller managing user authentication state.
class AuthController extends ChangeNotifier {
  AuthController({required this.authRepository});

  final AuthenticationRepository authRepository;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    } catch (e) {
      _currentUser = null;
      _isLoading = false;
      _errorMessage =
          'An unexpected authentication error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Terminates the current session.
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await authRepository.signOut();
    } finally {
      _currentUser = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
