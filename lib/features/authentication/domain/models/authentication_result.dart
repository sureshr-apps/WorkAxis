import 'package:workaxis/features/authentication/domain/models/app_user.dart';

/// Represents the typed outcome of an authentication attempt.
sealed class AuthenticationResult {
  const AuthenticationResult();

  const factory AuthenticationResult.success({
    required AppUser user,
    required String token,
  }) = AuthenticationSuccess;

  const factory AuthenticationResult.failure({required String errorMessage}) =
      AuthenticationFailure;
}

final class AuthenticationSuccess extends AuthenticationResult {
  const AuthenticationSuccess({required this.user, required this.token});

  final AppUser user;
  final String token;
}

final class AuthenticationFailure extends AuthenticationResult {
  const AuthenticationFailure({required this.errorMessage});

  final String errorMessage;
}
