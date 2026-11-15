import 'package:cloud_functions/cloud_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';

/// Maps a [FirebaseFunctionsException] to a typed [AppException].
///
/// Shared by every Cloud Functions client (`FirebaseCallableFunctions`,
/// `CallableDataGateway`) so callable failures are translated exactly once.
/// Server messages from `HttpsError` are authored to be user-safe.
AppException mapFunctionsError(FirebaseFunctionsException e, StackTrace st) {
  final serverMessage = e.message;
  switch (e.code) {
    case 'permission-denied':
    case 'unauthenticated':
      return AccessDeniedException('Callable ${e.code}', serverMessage);
    case 'not-found':
      return NotFoundException(
        'Callable ${e.code}',
        userMessage: serverMessage,
      );
    case 'unavailable':
      return NetworkException('Callable ${e.code}');
    case 'deadline-exceeded':
      return RequestTimeoutException('Callable ${e.code}');
    case 'invalid-argument':
    case 'already-exists':
    case 'failed-precondition':
    case 'resource-exhausted':
      return DatabaseException(
        'Callable ${e.code}',
        userMessage: serverMessage,
      );
    default:
      return mapBackendError(e, st);
  }
}
