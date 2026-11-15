import 'package:cloud_functions/cloud_functions.dart';
import 'package:workaxis/core/backend/functions_error_mapper.dart';
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

  /// Region shared by every WorkAxis callable (shared with the data gateway).
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
      throw mapFunctionsError(e, st);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
