/// Function returning the current instant. Inject instead of calling
/// `DateTime.now()` so time-dependent logic stays deterministic in tests.
typedef Now = DateTime Function();

/// Default production clock backed by the device clock.
///
/// Business-critical timestamps must still be server-confirmed once the real
/// backend is connected (AGENTS section 27); this only abstracts local time.
DateTime systemNow() => DateTime.now();

/// Small injectable clock.
class Clock {
  Clock([Now? now]) : _now = now ?? systemNow;

  /// A clock frozen at [instant], for tests.
  Clock.fixed(DateTime instant) : _now = (() => instant);

  final Now _now;

  DateTime now() => _now();
}
