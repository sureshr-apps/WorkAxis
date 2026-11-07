/// Monotonic token used to discard stale async responses.
///
/// ```dart
/// final token = _requests.next();
/// final data = await repository.load();
/// if (!_requests.isCurrent(token)) return; // superseded or reset
/// ```
class RequestGeneration {
  int _value = 0;

  /// Starts a new request, invalidating every earlier one.
  int next() => ++_value;

  /// Whether [token] is still the most recent request.
  bool isCurrent(int token) => token == _value;

  /// Invalidates all in-flight requests without starting a new one.
  void invalidate() => _value++;
}
