import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';

/// Presentation controller responsible for verifying and resolving user access rights.
class AccessController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  AccessController({required this.accessRepository, this.onResolved, Now? now})
    : _now = now ?? systemNow;

  /// A refresh requested within this window of the last successful resolve is
  /// skipped unless forced: screens refresh on every entry, and each refresh
  /// is a server round trip for the member and branches.
  static const Duration freshnessWindow = Duration(seconds: 60);

  final AccessRepository accessRepository;
  final Now _now;

  /// Called with the resolved context *before* listeners are notified, so
  /// dependent state (the active branch) is consistent when the router
  /// re-evaluates its redirect.
  final void Function(UserAccessContext context)? onResolved;

  final RequestGeneration _requests = RequestGeneration();

  UserAccessContext? _accessContext;
  AppUser? _resolvingUser;
  bool _isResolving = false;
  String? _errorMessage;
  DateTime? _resolvedAt;

  UserAccessContext? get accessContext => _accessContext;
  bool get isResolving => _isResolving;
  String? get errorMessage => _errorMessage;
  bool get hasResolved => _accessContext != null;

  /// Resolves access boundaries for the authenticated user.
  ///
  /// A response that arrives after a newer resolve or after [clear] (for
  /// example user A's context landing after user B signed in) is discarded and
  /// reported as `false`.
  Future<bool> resolveAccess(AppUser user) async {
    final token = _requests.next();
    _resolvingUser = user;
    _isResolving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final context = await accessRepository.resolveCurrentUserAccess(user);
      if (!_requests.isCurrent(token)) return false;
      _accessContext = context;
      _resolvedAt = _now();
      _isResolving = false;
      _errorMessage = null;
      onResolved?.call(context);
      notifyListeners();
      return true;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return false;
      _accessContext = null;
      _isResolving = false;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'We could not verify your access. Please try again.',
      );
      notifyListeners();
      return false;
    }
  }

  /// Silently refreshes access boundaries (such as after branches or assignments are modified)
  /// without clearing the current context, setting [isResolving] to true, or interrupting current navigation.
  ///
  /// Forced by default, so pull-to-refresh and post-mutation refreshes always
  /// reach the server. Screen-entry loads pass `force: false` to skip the round
  /// trip when access was resolved within [freshnessWindow]; a skipped refresh
  /// returns `false` and leaves the current context untouched.
  Future<bool> refreshAccess({bool force = true}) async {
    final user = _resolvingUser ?? _accessContext?.user;
    if (user == null) return false;
    if (!force && _isFresh) return false;
    // A refresh must never invalidate an in-flight sign-in resolution: that
    // would leave the router stuck on the "resolving" state.
    if (_isResolving) return false;
    final token = _requests.next();

    try {
      final context = await accessRepository.resolveCurrentUserAccess(user);
      if (!_requests.isCurrent(token)) return false;
      _accessContext = context;
      _resolvedAt = _now();
      _errorMessage = null;
      onResolved?.call(context);
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      // A failed refresh keeps the current context; callers get `false`.
      developer.log(
        'Unable to refresh access context.',
        name: 'workaxis.access',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  bool get _isFresh {
    final resolvedAt = _resolvedAt;
    return _accessContext != null &&
        resolvedAt != null &&
        _now().difference(resolvedAt) < freshnessWindow;
  }

  /// Retries resolution using the previously attempted user.
  Future<bool> retryResolveAccess() async {
    final user = _resolvingUser;
    if (user == null) return false;
    return resolveAccess(user);
  }

  /// Clears resolved access state upon sign out and invalidates any resolve
  /// that is still in flight.
  void clear() {
    _requests.invalidate();
    _accessContext = null;
    _resolvedAt = null;
    _resolvingUser = null;
    _isResolving = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void reset() => clear();
}
