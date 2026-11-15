import 'package:cloud_functions/cloud_functions.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/backend/functions_error_mapper.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';

/// Reads and writes relational data through the trusted `dataOp` callable.
///
/// Remote data sources depend on this contract rather than on a generated SDK,
/// so they can be unit-tested with a fake. Each [op] is a named operation
/// (`ListOrganizationsPaged`, `SubmitReturn`, ...) whose response has the shape
/// documented in `docs/backend-api.md`.
abstract interface class DataGateway {
  /// Runs [op] with [vars] and returns the operation's `data` object.
  ///
  /// Optional variables must be omitted when unset, never sent as null.
  /// Throws an [AppException] whose `userMessage` is safe to display.
  Future<Map<String, dynamic>> call(
    String op, [
    Map<String, dynamic> vars = const {},
  ]);
}

/// [DataGateway] backed by the `dataOp` Cloud Functions callable.
class CallableDataGateway implements DataGateway {
  CallableDataGateway({FirebaseFunctions? functions})
    : _customFunctions = functions;

  /// Name of the single data callable.
  static const String callableName = 'dataOp';

  final FirebaseFunctions? _customFunctions;

  /// Resolved lazily so constructing the repository graph does not require
  /// an initialized Firebase app.
  FirebaseFunctions get _functions =>
      _customFunctions ??
      FirebaseFunctions.instanceFor(
        region: FirebaseCallableFunctions.callableRegion,
      );

  @override
  Future<Map<String, dynamic>> call(
    String op, [
    Map<String, dynamic> vars = const {},
  ]) async {
    try {
      final result = await _functions.httpsCallable(callableName).call({
        'op': op,
        'vars': vars,
      });
      final body = result.data;
      final data = body is Map ? body['data'] : null;
      if (data is! Map) {
        throw DatabaseException('dataOp $op returned no data object');
      }
      return _normalize(data) as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e, st) {
      throw mapFunctionsError(e, st);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  /// Platform channels decode JSON objects as `Map<Object?, Object?>`; convert
  /// them recursively so mappers can rely on `Map<String, dynamic>`.
  static Object? _normalize(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _normalize(entry.value),
      };
    }
    if (value is List) return [for (final item in value) _normalize(item)];
    return value;
  }
}
