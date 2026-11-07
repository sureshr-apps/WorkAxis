import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/authentication_result.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/domain/repositories/authentication_repository.dart';

/// Production [AuthenticationRepository] using Firebase Authentication.
///
/// - Identifiers (username, email or phone) are resolved to the login email
///   by the `resolveLoginIdentifier` callable; the client never reads
///   `user_aliases`.
/// - Role, organization and status come from the ID token's custom claims,
///   which only trusted functions write from SQL (`docs/backend-api.md`).
///   Display fields (name, username, phone) come from the `users/{uid}`
///   projection. SQL is re-checked by the access repository afterwards.
/// - Fails closed: missing or unknown claims, or a non-active status, deny
///   the session and sign the user out.
class FirebaseAuthRepository implements AuthenticationRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    CallableFunctions? functions,
  }) : _customAuth = auth,
       _customFirestore = firestore,
       _customFunctions = functions;

  static const _invalidCredentials = 'Invalid username or password.';
  static const _profileUnavailable =
      'Your account is not available. Please contact your administrator.';
  static const _suspended =
      'Your account is suspended. Please contact your administrator.';

  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final CallableFunctions? _customFunctions;
  CallableFunctions? _defaultFunctions;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  CallableFunctions get _functions =>
      _customFunctions ?? (_defaultFunctions ??= FirebaseCallableFunctions());

  @override
  Future<AuthenticationResult> signIn({
    required String identifier,
    required String password,
  }) async {
    final rawId = identifier.trim();
    if (rawId.isEmpty) {
      return const AuthenticationResult.failure(
        errorMessage: 'Please enter your username, email, or phone number.',
      );
    }
    if (password.isEmpty) {
      return const AuthenticationResult.failure(
        errorMessage: 'Please enter your password.',
      );
    }

    try {
      final email = await _resolveEmail(rawId);
      if (email == null) {
        return const AuthenticationResult.failure(
          errorMessage: _invalidCredentials,
        );
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const AuthenticationResult.failure(
          errorMessage: 'Authentication failed. Please try again.',
        );
      }

      final session = await _loadSession(firebaseUser, forceRefresh: true);
      if (session == null) {
        await _safeSignOut();
        return const AuthenticationResult.failure(
          errorMessage: _profileUnavailable,
        );
      }
      if (session.user.status != AccountStatus.active) {
        await _safeSignOut();
        return const AuthenticationResult.failure(errorMessage: _suspended);
      }
      return AuthenticationResult.success(
        user: session.user,
        token: session.token,
      );
    } on FirebaseAuthException catch (e, st) {
      return AuthenticationResult.failure(
        errorMessage: _signInMessageFor(e, st),
      );
    } on _IdentifierRejected {
      return const AuthenticationResult.failure(
        errorMessage: _invalidCredentials,
      );
    } catch (e, st) {
      await _safeSignOut();
      return AuthenticationResult.failure(
        errorMessage: mapBackendError(e, st).userMessage,
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw const AuthenticationException(
        'No signed-in user with an email credential',
        userMessage: 'Please sign in again before changing your password.',
      );
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e, st) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const AuthenticationException(
          'Re-authentication failed',
          userMessage: 'Your current password is incorrect.',
        );
      }
      throw mapBackendError(e, st);
    }
  }

  /// Returns the signed-in user, `null` when nobody is signed in or the
  /// session is denied. Transient backend failures are thrown (mapped)
  /// instead of being reported as "signed out".
  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _resolveSessionUser(user);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) {
      if (firebaseUser == null) return null;
      return _resolveSessionUser(firebaseUser);
    });
  }

  Future<AppUser?> _resolveSessionUser(User firebaseUser) async {
    final _Session? session;
    try {
      session = await _loadSession(firebaseUser);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
    if (session == null || session.user.status != AccountStatus.active) {
      developer.log(
        'Session denied: claims missing, invalid or not active',
        name: 'workaxis.auth',
        level: 900,
      );
      await _safeSignOut();
      return null;
    }
    return session.user;
  }

  /// Resolves [rawId] to the login email through the trusted callable.
  /// Returns null (or throws [_IdentifierRejected]) when the identifier is
  /// unknown so callers answer with the generic credentials message.
  Future<String?> _resolveEmail(String rawId) async {
    try {
      final response = await _functions.call('resolveLoginIdentifier', {
        'identifier': rawId,
      });
      final email = response['email'];
      if (email is! String || email.isEmpty) return null;
      return email;
    } on AccessDeniedException {
      throw const _IdentifierRejected();
    } on AuthenticationException {
      throw const _IdentifierRejected();
    } on NotFoundException {
      throw const _IdentifierRejected();
    }
  }

  /// Builds the session from token claims plus the profile projection.
  /// `null` when the claims are missing or malformed (fail closed).
  Future<_Session?> _loadSession(
    User firebaseUser, {
    bool forceRefresh = false,
  }) async {
    final tokenResult = await firebaseUser.getIdTokenResult(forceRefresh);
    final claims = tokenResult.claims ?? const <String, dynamic>{};

    final role = _parseRole(claims['role']);
    final status = _parseStatus(claims['status']);
    if (role == null || status == null) return null;

    final orgClaim = claims['organizationId'];
    final organizationId = orgClaim is String && orgClaim.isNotEmpty
        ? orgClaim
        : null;
    if (role.isCustomerLevel && organizationId == null) return null;

    final profile = await _readProfile(firebaseUser.uid);
    final email = LoginEmail.displayable(
      profile['email'] as String? ?? firebaseUser.email,
    );
    final user = AppUser(
      id: firebaseUser.uid,
      name: profile['name'] as String? ?? firebaseUser.displayName ?? 'User',
      username: profile['username'] as String? ?? firebaseUser.uid,
      email: email.isEmpty ? null : email,
      phone: profile['phone'] as String?,
      role: role,
      status: status,
      organizationId: role.isCustomerLevel ? organizationId : null,
    );
    return _Session(user, tokenResult.token ?? '');
  }

  Future<Map<String, dynamic>> _readProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() ?? const {};
  }

  UserRole? _parseRole(Object? value) {
    if (value is! String) return null;
    return UserRole.values.where((r) => r.name == value).firstOrNull;
  }

  AccountStatus? _parseStatus(Object? value) {
    if (value is! String) return null;
    return AccountStatus.values.where((s) => s.name == value).firstOrNull;
  }

  Future<void> _safeSignOut() async {
    try {
      await _auth.signOut();
    } catch (e, st) {
      developer.log(
        'Sign-out after failed session resolution failed',
        name: 'workaxis.auth',
        level: 900,
        error: e,
        stackTrace: st,
      );
    }
  }

  String _signInMessageFor(FirebaseAuthException e, StackTrace st) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return _invalidCredentials;
      case 'user-disabled':
        return _suspended;
      default:
        return mapBackendError(e, st).userMessage;
    }
  }
}

class _Session {
  const _Session(this.user, this.token);

  final AppUser user;
  final String token;
}

/// Internal signal: the identifier did not resolve to an account.
class _IdentifierRejected implements Exception {
  const _IdentifierRejected();
}
