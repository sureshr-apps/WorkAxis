import 'package:workaxis/core/time/clock.dart';

/// Frozen "now" (2026-11-07 10:30 in Asia/Kolkata, expressed in UTC so it is
/// independent of the machine timezone) for tests that would otherwise depend
/// on `DateTime.now()`.
final DateTime testNow = DateTime.utc(2026, 11, 7, 5, 0);

/// A [Now] function that always returns [testNow].
DateTime fixedNow() => testNow;

/// A [Clock] frozen at [testNow].
Clock fixedClock() => Clock.fixed(testNow);
