import 'dart:async';

import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/data/mock_auth_data_source.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/authentication_result.dart';
import 'package:workaxis/features/authentication/domain/repositories/authentication_repository.dart';

/// Mock implementation of [AuthenticationRepository] using in-memory data source.
class MockAuthenticationRepository implements AuthenticationRepository {
  MockAuthenticationRepository({
    MockAuthDataSource? dataSource,
    this.delay = const Duration(milliseconds: 300),
  }) : _dataSource = dataSource ?? MockAuthDataSource();

  final MockAuthDataSource _dataSource;
  final Duration delay;

  /// Fixture credentials for the debug-only sign-in quick fill.
  MockAuthDataSource get dataSource => _dataSource;
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  @override
  Future<AuthenticationResult> signIn({
    required String identifier,
    required String password,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    final trimmedIdentifier = identifier.trim();
    if (trimmedIdentifier.isEmpty || password.isEmpty) {
      return const AuthenticationResult.failure(
        errorMessage: 'Identifier and password are required.',
      );
    }

    final record = _dataSource.findByIdentifier(trimmedIdentifier);
    final isPasswordMatch = record != null && record.password == password;
    if (record == null || !isPasswordMatch) {
      return const AuthenticationResult.failure(
        errorMessage: 'Invalid username, email, or password.',
      );
    }

    if (record.user.status != AccountStatus.active) {
      return const AuthenticationResult.failure(
        errorMessage:
            'Your account is inactive. Please contact your administrator.',
      );
    }

    _currentUser = record.user;
    _authStateController.add(_currentUser);

    return AuthenticationResult.success(
      user: record.user,
      token: 'mock-jwt-token-for-${record.user.id}',
    );
  }

  @override
  Future<void> signOut() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final user = _currentUser;
    if (user == null) {
      throw const AuthenticationException(
        'No signed-in user',
        userMessage: 'Please sign in again before changing your password.',
      );
    }
    final record = _dataSource.findByIdentifier(user.username);
    if (record == null || record.password != currentPassword) {
      throw const AuthenticationException(
        'Current password mismatch',
        userMessage: 'Your current password is incorrect.',
      );
    }
    if (newPassword.length < 8) {
      throw const AuthenticationException(
        'New password too short',
        userMessage: 'New password must be at least 8 characters long.',
      );
    }
    _dataSource.updatePassword(user.id, newPassword);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Stream<AppUser?> authStateChanges() => _authStateController.stream;

  void dispose() {
    _authStateController.close();
  }
}
