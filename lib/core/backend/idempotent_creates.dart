import 'dart:convert';

import 'package:workaxis/core/ids/request_ids.dart';

/// Makes create calls safe to retry.
///
/// Each distinct create (operation + variables) gets a `requestId` that is
/// kept until a call with it succeeds. Submitting the same details again
/// after a failure or a lost response reuses the id, so the server returns
/// what the first attempt saved instead of saving it twice. A success clears
/// the id, so a later identical submission is a new record.
class IdempotentCreates {
  IdempotentCreates({String Function()? newRequestId})
    : _newRequestId = newRequestId ?? RequestIds.uuidV4;

  final String Function() _newRequestId;
  final Map<String, String> _pending = {};

  /// Calls [send] with [vars] plus a `requestId` for this create.
  Future<T> run<T>(
    String operation,
    Map<String, Object?> vars,
    Future<T> Function(Map<String, Object?> varsWithRequestId) send,
  ) async {
    final key = '$operation ${jsonEncode(vars)}';
    final requestId = _pending.putIfAbsent(key, _newRequestId);
    final result = await send({...vars, 'requestId': requestId});
    _pending.remove(key);
    return result;
  }
}
