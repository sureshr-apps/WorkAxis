import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/authentication_result.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/domain/repositories/authentication_repository.dart';

/// Production implementation of [AuthenticationRepository] using Firebase Authentication
/// and Cloud Firestore for multi-identifier alias resolution (username/phone to email).
class FirebaseAuthRepository implements AuthenticationRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _customAuth = auth,
        _customFirestore = firestore;

  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

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
      // 1. Multi-identifier resolution: If not already an email, resolve alias to email
      final String resolvedEmail;
      if (rawId.contains('@')) {
        resolvedEmail = rawId.toLowerCase();
      } else {
        final aliasKey = rawId.toLowerCase().replaceAll(RegExp(r'\s+'), '');
        final aliasDoc =
            await _firestore.collection('user_aliases').doc(aliasKey).get();

        if (!aliasDoc.exists || aliasDoc.data() == null) {
          return AuthenticationResult.failure(
            errorMessage: 'No account found matching "$rawId".',
          );
        }

        final emailVal = aliasDoc.data()?['email'] as String?;
        if (emailVal == null || emailVal.isEmpty) {
          return const AuthenticationResult.failure(
            errorMessage: 'No email address associated with this account identifier.',
          );
        }
        resolvedEmail = emailVal.toLowerCase();
      }

      // 2. Perform Firebase Auth email/password sign-in
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const AuthenticationResult.failure(
          errorMessage: 'Authentication failed. Please try again.',
        );
      }

      // 3. Fetch structured profile from Firestore
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      final AppUser appUser;
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        appUser = _mapDocToAppUser(firebaseUser.uid, data, resolvedEmail);
      } else {
        // Fallback profile if Firestore user document is missing
        appUser = AppUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? resolvedEmail.split('@').first,
          username: resolvedEmail.split('@').first,
          email: resolvedEmail,
          phone: firebaseUser.phoneNumber,
          role: UserRole.employee,
          status: AccountStatus.active,
        );
      }

      // 4. Enforce account status check
      if (appUser.status == AccountStatus.suspended ||
          appUser.status == AccountStatus.disabled) {
        await _auth.signOut();
        return const AuthenticationResult.failure(
          errorMessage: 'Your account is suspended. Please contact your administrator.',
        );
      }

      // 5. Retrieve authentication token
      final String token = await firebaseUser.getIdToken() ?? '';

      return AuthenticationResult.success(user: appUser, token: token);
    } on FirebaseAuthException catch (e) {
      return AuthenticationResult.failure(errorMessage: _mapAuthError(e.code, e.message));
    } catch (e) {
      return AuthenticationResult.failure(
        errorMessage: 'Sign-in encountered an error: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return _mapDocToAppUser(user.uid, doc.data()!, user.email ?? '');
      }
      return AppUser(
        id: user.uid,
        name: user.displayName ?? user.email?.split('@').first ?? 'User',
        username: user.email?.split('@').first ?? 'user',
        email: user.email,
        phone: user.phoneNumber,
        role: UserRole.employee,
        status: AccountStatus.active,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists && doc.data() != null) {
          return _mapDocToAppUser(
            firebaseUser.uid,
            doc.data()!,
            firebaseUser.email ?? '',
          );
        }
        return AppUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ??
              firebaseUser.email?.split('@').first ??
              'User',
          username: firebaseUser.email?.split('@').first ?? 'user',
          email: firebaseUser.email,
          phone: firebaseUser.phoneNumber,
          role: UserRole.employee,
          status: AccountStatus.active,
        );
      } catch (_) {
        return null;
      }
    });
  }

  AppUser _mapDocToAppUser(
    String uid,
    Map<String, dynamic> data,
    String fallbackEmail,
  ) {
    final roleStr = data['role'] as String? ?? 'employee';
    final statusStr = data['status'] as String? ?? 'active';

    final role = UserRole.values.firstWhere(
      (r) => r.name.toLowerCase() == roleStr.toLowerCase(),
      orElse: () => UserRole.employee,
    );

    final status = AccountStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => AccountStatus.active,
    );

    return AppUser(
      id: uid,
      name: data['name'] as String? ?? 'User',
      username: data['username'] as String? ?? uid,
      email: data['email'] as String? ?? fallbackEmail,
      phone: data['phone'] as String?,
      role: role,
      status: status,
      organizationId: data['organizationId'] as String?,
    );
  }

  String _mapAuthError(String code, String? fallback) {
    switch (code) {
      case 'user-not-found':
        return 'No account found matching this identifier.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please verify and try again.';
      case 'user-disabled':
        return 'This account has been disabled or suspended.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again in a few minutes.';
      case 'network-request-failed':
        return 'Network connection error. Check your internet connectivity.';
      case 'invalid-email':
        return 'The provided email format is invalid.';
      default:
        return fallback ?? 'Authentication failed ($code).';
    }
  }
}
