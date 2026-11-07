import 'package:workaxis/core/backend/callable_functions.dart';

/// Records callable invocations and answers from per-name handlers.
class FakeCallableFunctions implements CallableFunctions {
  FakeCallableFunctions([
    Map<String, Future<Map<String, dynamic>> Function(Map<String, dynamic>)>?
    handlers,
  ]) : handlers = handlers ?? {};

  final Map<String, Future<Map<String, dynamic>> Function(Map<String, dynamic>)>
  handlers;
  final List<({String name, Map<String, dynamic> payload})> calls = [];

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> payload = const {},
  ]) async {
    calls.add((name: name, payload: Map.of(payload)));
    final handler = handlers[name];
    if (handler == null) throw StateError('No handler for callable $name');
    return handler(payload);
  }

  Iterable<Map<String, dynamic>> payloadsOf(String name) =>
      calls.where((c) => c.name == name).map((c) => c.payload);
}
