import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/session/session_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

import '../../helpers/session_fakes.dart';

void main() {
  late FakeAuthRepository authRepo;
  late AuthController auth;
  late AccessController access;
  late BranchContextController branch;
  late CountingScoped orgScoped;
  late CountingScoped branchScopedA;
  late CountingScoped branchScopedB;
  late SessionController session;

  final branches = [testBranch('br-1'), testBranch('br-2')];

  setUp(() {
    final user = testUser(UserRole.branchManager);
    authRepo = FakeAuthRepository(user);
    branch = BranchContextController();
    access = AccessController(
      accessRepository: FakeAccessRepository(
        (u) => branchManagerContext(u, branches),
      ),
      onResolved: branch.initFromAccessContext,
    );
    auth = AuthController(authRepository: authRepo);
    orgScoped = CountingScoped();
    branchScopedA = CountingScoped();
    branchScopedB = CountingScoped();
    session = SessionController(
      auth: auth,
      access: access,
      branch: branch,
      sessionScoped: [orgScoped, branchScopedA, branchScopedB],
      branchScoped: [branchScopedA, branchScopedB],
    );
  });

  tearDown(() {
    session.dispose();
    auth.dispose();
    access.dispose();
    branch.dispose();
  });

  Future<AppUser> signIn() async {
    await auth.signIn(identifier: 'x', password: 'y');
    final user = auth.currentUser!;
    await access.resolveAccess(user);
    branch.selectBranch(branches.first);
    return user;
  }

  group('SessionController.signOut', () {
    test(
      'clears user, access, branch and resets every scoped controller',
      () async {
        await signIn();
        expect(access.hasResolved, isTrue);
        expect(branch.hasActiveBranch, isTrue);
        final resetsBefore = branchScopedA.resets;

        await session.signOut();

        expect(auth.isAuthenticated, isFalse);
        expect(access.accessContext, isNull);
        expect(branch.activeBranch, isNull);
        expect(branch.assignedBranches, isEmpty);
        expect(orgScoped.resets, 1);
        expect(branchScopedA.resets, greaterThan(resetsBefore));
        expect(branchScopedB.resets, branchScopedA.resets);
        expect(authRepo.signOutCalls, 1);
      },
    );

    test('nulls the user before any scoped state is cleared', () async {
      await signIn();
      bool? userWasNullAtFirstReset;
      orgScoped.onReset = () =>
          userWasNullAtFirstReset ??= !auth.isAuthenticated;

      await session.signOut();

      expect(userWasNullAtFirstReset, isTrue);
    });

    test('still wipes local state when the identity provider fails', () async {
      await signIn();
      authRepo.failSignOut = true;

      await session.signOut(); // must not throw

      expect(auth.isAuthenticated, isFalse);
      expect(access.accessContext, isNull);
      expect(orgScoped.resets, 1);
    });

    test('a pending access resolution cannot land after sign-out', () async {
      final user = testUser(UserRole.branchManager);
      await auth.signIn(identifier: 'x', password: 'y');
      final gate = Completer<void>();
      (access.accessRepository as FakeAccessRepository).gates[user.id] = gate;

      final resolving = access.resolveAccess(user);
      await session.signOut();
      gate.complete();

      expect(await resolving, isFalse);
      expect(access.accessContext, isNull);
    });
  });

  group('active branch changes', () {
    test('reset only branch-scoped controllers', () async {
      await signIn();
      final orgBefore = orgScoped.resets;
      final aBefore = branchScopedA.resets;

      branch.selectBranch(branches.last);

      expect(branchScopedA.resets, aBefore + 1);
      expect(branchScopedB.resets, aBefore + 1);
      expect(orgScoped.resets, orgBefore);
    });

    test('re-selecting the same branch does not reset', () async {
      await signIn();
      final before = branchScopedA.resets;

      branch.selectBranch(branches.first);

      expect(branchScopedA.resets, before);
    });
  });

  test('identity-provider sign-out wipes session state', () async {
    await auth.init();
    await signIn();

    authRepo.states.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(auth.isAuthenticated, isFalse);
    expect(access.accessContext, isNull);
    expect(orgScoped.resets, 1);
  });
}
