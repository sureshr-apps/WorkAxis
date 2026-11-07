import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/routing/app_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

import '../../helpers/session_fakes.dart';

class _Harness {
  _Harness(this.role, {this.branches = const []}) {
    user = testUser(role);
    auth = FakeAuthRepository(user);
    branchController = BranchContextController();
    accessController = AccessController(
      accessRepository: FakeAccessRepository(_contextFor),
      onResolved: branchController.initFromAccessContext,
    );
    authController = AuthController(authRepository: auth);
  }

  final UserRole role;
  final List<BranchSummary> branches;
  late final AppUser user;
  late final FakeAuthRepository auth;
  late final AuthController authController;
  late final AccessController accessController;
  late final BranchContextController branchController;

  UserAccessContext _contextFor(AppUser user) {
    if (role == UserRole.branchManager) {
      return branchManagerContext(user, branches);
    }
    return UserAccessContext(
      user: user,
      organization: role.isPlatformLevel ? null : testOrganization,
    );
  }

  Future<void> signInAndResolve() async {
    await authController.signIn(identifier: 'x', password: 'y');
    await accessController.resolveAccess(user);
  }

  String? redirect(String location) => resolveRedirect(
    matchedLocation: location,
    authController: authController,
    accessController: accessController,
    branchController: branchController,
  );

  void dispose() {
    authController.dispose();
    accessController.dispose();
    branchController.dispose();
  }
}

Future<_Harness> _resolved(
  UserRole role, {
  List<BranchSummary> branches = const [],
}) async {
  final h = _Harness(role, branches: branches);
  addTearDown(h.dispose);
  await h.signInAndResolve();
  return h;
}

void main() {
  group('startup and authentication guards', () {
    test(
      'shows the splash while the previous session is being restored',
      () async {
        final h = _Harness(UserRole.employee);
        addTearDown(h.dispose);

        final init = h.authController.init();
        expect(h.authController.isInitializing, isTrue);
        expect(h.redirect(AppRoutes.employeeWorkspace), AppRoutes.splash);
        expect(h.redirect(AppRoutes.splash), isNull);

        await init;
        expect(h.authController.isInitializing, isFalse);
        expect(h.redirect(AppRoutes.splash), AppRoutes.signIn);
      },
    );

    test(
      'a restored session leaves the splash for access verification',
      () async {
        final h = _Harness(UserRole.employee);
        addTearDown(h.dispose);
        h.auth.restoreSession();

        await h.authController.init();

        expect(h.authController.isAuthenticated, isTrue);
        expect(h.redirect(AppRoutes.splash), AppRoutes.verifyAccess);
      },
    );

    test('unauthenticated users can only be on sign-in', () {
      final h = _Harness(UserRole.employee);
      addTearDown(h.dispose);

      expect(h.redirect(AppRoutes.signIn), isNull);
      for (final route in [
        AppRoutes.employeeWorkspace,
        AppRoutes.platformWorkspace,
        AppRoutes.orgAdminWorkspace,
        AppRoutes.selectBranch,
        AppRoutes.verifyAccess,
        '/does-not-exist',
      ]) {
        expect(h.redirect(route), AppRoutes.signIn, reason: route);
      }
    });

    test('authenticated users without access stay on verification', () async {
      final h = _Harness(UserRole.employee);
      addTearDown(h.dispose);
      await h.authController.signIn(identifier: 'x', password: 'y');

      expect(h.redirect(AppRoutes.verifyAccess), isNull);
      expect(h.redirect(AppRoutes.employeeWorkspace), AppRoutes.verifyAccess);
      expect(h.redirect(AppRoutes.signIn), AppRoutes.verifyAccess);
    });
  });

  group('role area protection', () {
    const areas = {
      'platform': AppRoutes.platformOrganizations,
      'organization': AppRoutes.orgAdminBranches,
      'branch-manager': AppRoutes.branchManagerAttendance,
      'employee': AppRoutes.employeeProfile,
    };
    const ownArea = {
      UserRole.platformOwner: 'platform',
      UserRole.platformAdmin: 'platform',
      UserRole.orgAdmin: 'organization',
      UserRole.employee: 'employee',
      UserRole.branchManager: 'branch-manager',
    };
    const landing = {
      UserRole.platformOwner: AppRoutes.platformWorkspace,
      UserRole.platformAdmin: AppRoutes.platformWorkspace,
      UserRole.orgAdmin: AppRoutes.orgAdminWorkspace,
      UserRole.employee: AppRoutes.employeeWorkspace,
      UserRole.branchManager: AppRoutes.branchManagerWorkspace,
    };

    for (final role in UserRole.values) {
      test('${role.name} is bounced from every other role area', () async {
        final h = await _resolved(role, branches: [testBranch('br-1')]);

        for (final entry in areas.entries) {
          final redirect = h.redirect(entry.value);
          if (entry.key == ownArea[role]) {
            expect(redirect, isNull, reason: '${role.name} -> ${entry.value}');
          } else {
            expect(
              redirect,
              landing[role],
              reason: '${role.name} -> ${entry.value}',
            );
          }
        }
      });

      test(
        '${role.name} leaves verification once access is resolved',
        () async {
          final h = await _resolved(role, branches: [testBranch('br-1')]);

          expect(h.redirect(AppRoutes.verifyAccess), landing[role]);
          expect(h.redirect(AppRoutes.signIn), AppRoutes.verifyAccess);
        },
      );
    }

    test('only the platform owner may open platform users', () async {
      final admin = await _resolved(UserRole.platformAdmin);
      final owner = await _resolved(UserRole.platformOwner);

      expect(
        admin.redirect(AppRoutes.platformUsers),
        AppRoutes.platformWorkspace,
      );
      expect(owner.redirect(AppRoutes.platformUsers), isNull);
    });

    test(
      'select-branch and no-branch screens are for branch managers only',
      () async {
        for (final role in UserRole.values.where(
          (r) => r != UserRole.branchManager,
        )) {
          final h = await _resolved(role);
          expect(
            h.redirect(AppRoutes.selectBranch),
            landing[role],
            reason: role.name,
          );
          expect(
            h.redirect(AppRoutes.noBranchAssigned),
            landing[role],
            reason: role.name,
          );
        }
      },
    );
  });

  group('branch manager gating', () {
    test(
      'zero assigned branches is always gated to the no-branch screen',
      () async {
        final h = await _resolved(UserRole.branchManager);

        expect(h.branchController.hasActiveBranch, isFalse);
        expect(h.redirect(AppRoutes.noBranchAssigned), isNull);
        for (final route in [
          AppRoutes.branchManagerWorkspace,
          AppRoutes.branchManagerAttendance,
          AppRoutes.selectBranch,
          AppRoutes.verifyAccess,
          AppRoutes.employeeWorkspace,
        ]) {
          expect(h.redirect(route), AppRoutes.noBranchAssigned, reason: route);
        }
      },
    );

    test('only inactive branches behave like zero branches', () async {
      final h = await _resolved(
        UserRole.branchManager,
        branches: [testBranch('br-x', isActive: false)],
      );

      expect(
        h.redirect(AppRoutes.branchManagerWorkspace),
        AppRoutes.noBranchAssigned,
      );
    });

    test('one active branch (plus an inactive one) is auto-selected', () async {
      final h = await _resolved(
        UserRole.branchManager,
        branches: [testBranch('br-1'), testBranch('br-2', isActive: false)],
      );

      expect(h.branchController.activeBranch?.branchId, 'br-1');
      expect(h.redirect(AppRoutes.branchManagerWorkspace), isNull);
      expect(h.redirect(AppRoutes.branchManagerReturns), isNull);
      expect(
        h.redirect(AppRoutes.noBranchAssigned),
        AppRoutes.branchManagerWorkspace,
      );
      expect(
        h.redirect(AppRoutes.verifyAccess),
        AppRoutes.branchManagerWorkspace,
      );
    });

    test(
      'multiple branches require a selection before any branch screen',
      () async {
        final branches = [testBranch('br-1'), testBranch('br-2')];
        final h = await _resolved(UserRole.branchManager, branches: branches);

        expect(h.branchController.hasActiveBranch, isFalse);
        expect(h.redirect(AppRoutes.selectBranch), isNull);
        for (final route in [
          AppRoutes.branchManagerWorkspace,
          AppRoutes.branchManagerEmployees,
          AppRoutes.verifyAccess,
        ]) {
          expect(h.redirect(route), AppRoutes.selectBranch, reason: route);
        }

        expect(h.branchController.selectBranch(branches.last), isTrue);

        expect(h.redirect(AppRoutes.branchManagerWorkspace), isNull);
        // Changing branch later is still possible.
        expect(h.redirect(AppRoutes.selectBranch), isNull);
      },
    );
  });
}
