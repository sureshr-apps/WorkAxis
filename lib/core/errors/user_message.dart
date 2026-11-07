import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';

/// Returns text that is safe to show to users for any thrown [error].
///
/// Typed failures with a specific category (network, timeout, access denied,
/// not found, authentication) surface their own message. Everything else
/// (including raw exceptions) collapses to [fallback]; the raw error is logged
/// by [mapBackendError] and never displayed.
String userMessageFor(
  Object error,
  StackTrace? stackTrace, {
  required String fallback,
}) {
  final mapped = mapBackendError(error, stackTrace);
  if (mapped is DatabaseException && !mapped.hasCustomUserMessage) {
    return fallback;
  }
  return mapped.userMessage;
}
