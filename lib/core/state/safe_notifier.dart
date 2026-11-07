import 'package:flutter/foundation.dart';

/// Makes `notifyListeners` a no-op after `dispose`, so late async completions
/// cannot throw "used after being disposed".
mixin SafeNotifier on ChangeNotifier {
  bool _isDisposed = false;

  /// Whether [dispose] has been called.
  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
