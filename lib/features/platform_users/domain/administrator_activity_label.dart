/// Human-readable "last active" text, computed against an injected [now] so
/// the output is deterministic in tests.
abstract final class AdministratorActivityLabel {
  /// e.g. `Never`, `5m ago`, `3h ago`, `Yesterday`, `4d ago`.
  static String short(DateTime? lastActive, DateTime now) {
    if (lastActive == null) return 'Never';
    final elapsed = now.difference(lastActive);
    if (elapsed.inMinutes < 60) {
      return '${_atLeastZero(elapsed.inMinutes)}m ago';
    }
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    if (elapsed.inDays == 1) return 'Yesterday';
    return '${elapsed.inDays}d ago';
  }

  /// e.g. `Never signed in`, `Active 5m ago`, `Active yesterday`.
  static String sentence(DateTime? lastActive, DateTime now) {
    if (lastActive == null) return 'Never signed in';
    final text = short(lastActive, now);
    return 'Active ${text == 'Yesterday' ? 'yesterday' : text}';
  }

  static int _atLeastZero(int value) => value < 0 ? 0 : value;
}
