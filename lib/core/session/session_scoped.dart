/// State holder whose contents belong to the current signed-in session and must
/// be wiped on sign-out (or when the surrounding scope, such as the active
/// branch, changes).
abstract interface class SessionScoped {
  /// Discards all loaded data, filters and errors and invalidates any in-flight
  /// request so late responses cannot repopulate the state.
  void reset();
}
