import 'dart:async';

import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/authentication_result.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/domain/repositories/authentication_repository.dart';

/// Fixture organization used by session/router tests.
const testOrganization = OrganizationSummary(
  id: 'org-test',
  name: 'Test Org',
  code: 'TST',
);

/// Builds a user of [role] with stable ids.
AppUser testUser(UserRole role, {String id = 'user-1'}) => AppUser(
  id: id,
  name: 'Test ${role.name}',
  username: '${role.name}-$id',
  role: role,
  organizationId: role.isPlatformLevel ? null : testOrganization.id,
);

/// Builds a branch summary for [id].
BranchSummary testBranch(String id, {bool isActive = true}) => BranchSummary(
  id: id,
  organizationId: testOrganization.id,
  name: 'Branch $id',
  code: id.toUpperCase(),
  location: 'City',
  isActive: isActive,
);

/// Authentication repository that signs in as a fixed [user].
class FakeAuthRepository implements AuthenticationRepository {
  FakeAuthRepository(this.user);

  AppUser? user;
  AppUser? _current;
  bool failSignOut = false;
  int signOutCalls = 0;
  final StreamController<AppUser?> states = StreamController.broadcast();

  @override
  Future<AuthenticationResult> signIn({
    required String identifier,
    required String password,
  }) async {
    _current = user;
    return AuthenticationResult.success(user: user!, token: 't');
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (failSignOut) throw StateError('provider down');
    _current = null;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<AppUser?> getCurrentUser() async => _current;

  /// Pretends a session already exists (as after a page refresh).
  void restoreSession() => _current = user;

  @override
  Stream<AppUser?> authStateChanges() => states.stream;
}

/// Access repository returning a prebuilt context, optionally gated by a
/// completer so tests control response timing.
class FakeAccessRepository implements AccessRepository {
  FakeAccessRepository(this.contextFor);

  final UserAccessContext Function(AppUser user) contextFor;
  final Map<String, Completer<void>> gates = {};

  @override
  Future<UserAccessContext> resolveCurrentUserAccess(AppUser user) async {
    final gate = gates[user.id];
    if (gate != null) await gate.future;
    return contextFor(user);
  }

  @override
  Future<List<BranchSummary>> getAssignedBranches(String userId) async =>
      const [];

  @override
  Future<bool> validateBranchAccess({
    required String userId,
    required String branchId,
  }) async => true;
}

/// Access context for a Branch Manager with [branches].
UserAccessContext branchManagerContext(
  AppUser user,
  List<BranchSummary> branches,
) {
  final active = branches.where((b) => b.isActive).toList();
  return UserAccessContext(
    user: user,
    organization: testOrganization,
    assignedBranches: branches,
    activeBranch: active.length == 1
        ? ActiveBranchContext.fromBranch(active.single)
        : null,
  );
}

/// Counts resets and optionally runs a probe at reset time.
class CountingScoped implements SessionScoped {
  int resets = 0;
  void Function()? onReset;

  @override
  void reset() {
    resets++;
    onReset?.call();
  }
}
