import 'package:workaxis/core/backend/data_gateway.dart';

/// Records [DataGateway] calls and answers from per-operation handlers or
/// scripted maps.
class FakeDataGateway implements DataGateway {
  FakeDataGateway([
    Map<String, Map<String, dynamic> Function(Map<String, dynamic>)>? handlers,
  ]) : handlers = handlers ?? {};

  final Map<String, Map<String, dynamic> Function(Map<String, dynamic>)>
  handlers;
  final List<({String op, Map<String, dynamic> vars})> calls = [];

  /// Scripts a fixed response for [op].
  void respond(String op, Map<String, dynamic> data) =>
      handlers[op] = (_) => data;

  @override
  Future<Map<String, dynamic>> call(
    String op, [
    Map<String, dynamic> vars = const {},
  ]) async {
    calls.add((op: op, vars: Map.of(vars)));
    final handler = handlers[op];
    if (handler == null) throw StateError('No handler for data op $op');
    return handler(vars);
  }

  /// Variables of every call to [op], in order.
  List<Map<String, dynamic>> varsOf(String op) =>
      calls.where((c) => c.op == op).map((c) => c.vars).toList();

  /// Variables of the only call to [op].
  Map<String, dynamic> singleVarsOf(String op) {
    final all = varsOf(op);
    if (all.length != 1) {
      throw StateError('Expected one $op call, got ${all.length}');
    }
    return all.single;
  }
}
