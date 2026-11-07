import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';

/// Presentation controller responsible for verifying and resolving user access rights.
class AccessController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  AccessController({required this.accessRepository, this.onResolved});

  final AccessRepository accessRepository;

  /// Called with the resolved context *before* listeners are notified, so
  /// dependent state (the active branch) is consistent when the router
  /// re-evaluates its redirect.
  final void Function(UserAccessContext context)? onResolved;

  final RequestGeneration _requests = RequestGeneration();

  UserAccessContext? _accessContext;
  AppUser? _resolvingUser;
  bool _isResolving = false;
  String? _errorMessage;

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
    _resolvingUser = null;
    _isResolving = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void reset() => clear();
}
