import 'package:cloud_functions/cloud_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';

/// Invokes trusted server-side operations (Cloud Functions callables).
///
/// Repositories depend on this contract rather than on `cloud_functions`
/// directly, so they can be unit-tested with a fake. Callable names and
/// payloads are documented in `docs/backend-api.md`.
abstract interface class CallableFunctions {
  /// Calls [name] with [payload] and returns the decoded response map.
  ///
  /// Throws an [AppException] whose `userMessage` is safe to display.
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> payload = const {},
  ]);
}

/// [CallableFunctions] backed by Firebase Cloud Functions.
class FirebaseCallableFunctions implements CallableFunctions {
  FirebaseCallableFunctions({FirebaseFunctions? functions})
    : _customFunctions = functions;

  /// Region shared by every WorkAxis callable (matches Data Connect).
  static const String callableRegion = 'asia-south1';

  final FirebaseFunctions? _customFunctions;

  /// Resolved lazily so constructing the repository graph does not require
  /// an initialized Firebase app.
  FirebaseFunctions get _functions =>
      _customFunctions ?? FirebaseFunctions.instanceFor(region: callableRegion);

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> payload = const {},
  ]) async {
    try {
      final result = await _functions.httpsCallable(name).call(payload);
      final data = result.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return const {};
    } on FirebaseFunctionsException catch (e, st) {
      throw _mapFunctionsError(e, st);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  AppException _mapFunctionsError(FirebaseFunctionsException e, StackTrace st) {
    // Server messages from HttpsError are authored to be user-safe.
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
}
