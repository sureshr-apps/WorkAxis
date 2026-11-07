import 'dart:async';

import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

/// Owns the lifecycle of everything that belongs to one signed-in session.
///
/// App-lifetime controllers hold per-user data (summaries, rows, filters). This
/// class is the single place that wipes them, so a user signing out on a shared
/// device never leaves their data for the next user:
///
/// * [signOut] is the only supported sign-out path (shell, verification,
///   branch selection, profile, no-branch screens).
/// * An identity-provider-initiated sign-out (revoked token, disabled account)
///   triggers the same cleanup.
/// * Changing the active branch resets branch-scoped controllers so data from
///   the previous branch is never displayed under the new one.
class SessionController {
  SessionController({
    required this._auth,
    required this._access,
    required this._branch,
    required List<SessionScoped> sessionScoped,
    List<SessionScoped> branchScoped = const [],
  }) : _sessionScoped = List.unmodifiable(sessionScoped),
       _branchScoped = List.unmodifiable(branchScoped),
       _lastBranchId = _branch.activeBranch?.branchId {
    _auth.onSessionLost = _clearSessionState;
    _branch.addListener(_onBranchChanged);
  }

  final AuthController _auth;
  final AccessController _access;
  final BranchContextController _branch;
  final List<SessionScoped> _sessionScoped;
  final List<SessionScoped> _branchScoped;
  String? _lastBranchId;

  /// Signs the current user out and wipes all session-scoped state.
  ///
  /// Order matters: the local user is nulled first (so the router leaves
  /// protected routes and the verification screen cannot resolve access for a
  /// departing user), in-flight access resolution is invalidated, scoped state
  /// is cleared, and only then is the identity provider called. A failure at
  /// the provider is logged by [AuthController] and never leaves local state
  /// populated.
  Future<void> signOut() async {
    // AuthController.signOut clears the user synchronously before awaiting.
    final remote = _auth.signOut();
    _clearSessionState();
    await remote;
  }

  void _clearSessionState() {
    _access.clear();
    _branch.clear();
    for (final scoped in _sessionScoped) {
      scoped.reset();
    }
  }

  void _onBranchChanged() {
    final currentId = _branch.activeBranch?.branchId;
    if (currentId == _lastBranchId) return;
    _lastBranchId = currentId;
    for (final scoped in _branchScoped) {
      scoped.reset();
    }
  }

  void dispose() {
    _branch.removeListener(_onBranchChanged);
    if (_auth.onSessionLost == _clearSessionState) {
      _auth.onSessionLost = null;
    }
  }
}
