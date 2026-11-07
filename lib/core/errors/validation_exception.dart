import 'package:workaxis/core/errors/app_exceptions.dart';

/// Thrown when input or a requested change violates a business rule.
///
/// [userMessage] is always specific and safe to show (it is authored by the
/// validator, never taken from a backend error).
class ValidationException extends AppException {
  ValidationException(super.message) : super(userMessage: message);

  @override
  String get defaultUserMessage => 'Please check the details and try again.';
}
