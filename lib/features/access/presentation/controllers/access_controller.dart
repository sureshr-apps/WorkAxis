import 'package:flutter/foundation.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';

/// Presentation controller responsible for verifying and resolving user access rights.
class AccessController extends ChangeNotifier {
  AccessController({required this.accessRepository});

  final AccessRepository accessRepository;

  UserAccessContext? _accessContext;
  AppUser? _resolvingUser;
  bool _isResolving = false;
  String? _errorMessage;

  UserAccessContext? get accessContext => _accessContext;
  bool get isResolving => _isResolving;
  String? get errorMessage => _errorMessage;
  bool get hasResolved => _accessContext != null;

  /// Resolves access boundaries for the authenticated user.
  Future<bool> resolveAccess(AppUser user) async {
    _resolvingUser = user;
    _isResolving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final context = await accessRepository.resolveCurrentUserAccess(user);
      _accessContext = context;
      _isResolving = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _accessContext = null;
      _isResolving = false;
      _errorMessage = e.toString();
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

  /// Clears resolved access state upon sign out.
  void clear() {
    _accessContext = null;
    _resolvingUser = null;
    _isResolving = false;
    _errorMessage = null;
    notifyListeners();
  }
}
