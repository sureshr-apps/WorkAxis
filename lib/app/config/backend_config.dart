import 'package:flutter/foundation.dart';

/// Defines the backend persistence and API mode for WorkAxis.
enum BackendMode {
  /// Local mock repositories for offline prototyping, development fixtures,
  /// and hermetic widget testing.
  mock,

  /// Live Firebase infrastructure using Firebase Authentication, Cloud Firestore
  /// (NoSQL for exponential events), and Firebase Data Connect / PostgreSQL.
  firebase,
}

/// Central configuration managing the active backend provider.
class BackendConfig {
  BackendConfig._();

  /// The active backend persistence mode.
  /// Defaults to [BackendMode.mock] during development / testing,
  /// or can be configured via environment variable `BACKEND_MODE=firebase`.
  static BackendMode mode =
      const String.fromEnvironment('BACKEND_MODE') == 'firebase'
      ? BackendMode.firebase
      : BackendMode.mock;

  /// Returns true when running in Firebase live backend mode.
  static bool get isFirebase => mode == BackendMode.firebase;

  /// Returns true when running in local mock fixture mode.
  static bool get isMock => mode == BackendMode.mock;

  /// Throws when the mock backend would ship in a release build.
  ///
  /// Mock repositories contain fixture credentials and fake data; a release
  /// build must be created with `--dart-define=BACKEND_MODE=firebase`.
  static void assertReleaseSafe({bool isRelease = kReleaseMode}) {
    if (isRelease && isMock) {
      throw StateError('Mock backend is not permitted in release builds.');
    }
  }

  /// Programmatically override the backend mode (e.g. during integration tests).
  static void setMode(BackendMode newMode) {
    mode = newMode;
  }
}
