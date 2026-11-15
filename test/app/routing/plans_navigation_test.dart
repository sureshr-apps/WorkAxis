import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/routing/role_destinations.dart';
import 'package:workaxis/app/shell/adaptive_app_shell.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

import '../../helpers/session_fakes.dart';

const List<UserRole> _nonPlatformRoles = [
  UserRole.orgAdmin,
  UserRole.branchManager,
  UserRole.employee,
];

/// Resolves [role] through the same guard chain the router uses and returns
/// the redirect for [location] (null when the route may be shown).
Future<String?> _redirectFor(UserRole role, String location) async {
  final user = testUser(role);
  final authController = AuthController(
    authRepository: FakeAuthRepository(user),
  );
  final branchController = BranchContextController();
  final accessController = AccessController(
    accessRepository: FakeAccessRepository(
      (u) => UserAccessContext(
        user: u,
        organization: role.isPlatformLevel ? null : testOrganization,
      ),
    ),
    onResolved: branchController.initFromAccessContext,
  );
  addTearDown(() {
    authController.dispose();
    accessController.dispose();
    branchController.dispose();
  });

  await authController.signIn(identifier: 'x', password: 'y');
  await accessController.resolveAccess(user);

  return resolveRedirect(
    matchedLocation: location,
    authController: authController,
    accessController: accessController,
    branchController: branchController,
  );
}

Widget _shell({
  required Size size,
  required List<AppNavDestination> destinations,
}) {
  final authController = AuthController(
    authRepository: MockAuthenticationRepository(delay: Duration.zero),
  );
  final accessController = AccessController(
    accessRepository: MockAccessRepository(delay: Duration.zero),
  );
  final branchController = BranchContextController();
  return MaterialApp(
    theme: AppTheme.light,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<AccessController>.value(value: accessController),
        ChangeNotifierProvider<BranchContextController>.value(
          value: branchController,
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: AdaptiveAppShell(
          currentRoute: AppRoutes.platformPlans,
          destinations: destinations,
          child: const Text('Plans body'),
        ),
      ),
    ),
  );
}

void main() {
  group('navigation destinations', () {
    test(
      'platform owner sees Plans between Organizations and Platform Users',
      () {
        final labels = RoleDestinations.platform(isOwner: true)
            .map((d) => d.label)
            .toList();

        expect(labels, [
          'Home',
          'Organizations',
          'Plans',
          'Platform Users',
          'Settings',
        ]);
      },
    );

    test('platform administrator sees Plans but not Platform Users', () {
      final destinations = RoleDestinations.platform(isOwner: false);
      final labels = destinations.map((d) => d.label).toList();

      expect(labels, ['Home', 'Organizations', 'Plans', 'Settings']);
      final plans = destinations.singleWhere((d) => d.label == 'Plans');
      expect(plans.route, AppRoutes.platformPlans);
      expect(plans.icon, Icons.layers_outlined);
      expect(plans.selectedIcon, Icons.layers);
    });

    test('no customer-side role has a Plans destination', () {
      final customerLists = {
        'organization admin': RoleDestinations.organizationAdmin,
        'branch manager': RoleDestinations.branchManager,
        'employee': RoleDestinations.employee,
      };
      for (final entry in customerLists.entries) {
        expect(
          entry.value.any(
            (d) => d.label == 'Plans' || d.route.startsWith('/platform'),
          ),
          isFalse,
          reason: entry.key,
        );
      }
    });

    test('plan routes are built from one convention', () {
      expect(AppRoutes.platformPlans, '/platform/plans');
      expect(AppRoutes.platformPlansAdd, '/platform/plans/add');
      expect(
        AppRoutes.platformPlanEditPath('plan-pro'),
        '/platform/plans/plan-pro/edit',
      );
    });
  });

  group('route protection', () {
    const planLocations = [AppRoutes.platformPlans, AppRoutes.platformPlansAdd];

    test('the pure guard lets platform roles open the plan routes', () {
      for (final role in [UserRole.platformOwner, UserRole.platformAdmin]) {
        for (final location in [
          ...planLocations,
          AppRoutes.platformPlanEditPath('plan-pro'),
        ]) {
          expect(
            redirectForRoleRoute(role: role, matchedLocation: location),
            isNull,
            reason: '$role $location',
          );
        }
      }
    });

    test('the pure guard sends customer roles to their own landing route', () {
      for (final role in _nonPlatformRoles) {
        for (final location in [
          ...planLocations,
          AppRoutes.platformPlanEditPath('plan-pro'),
        ]) {
          expect(
            redirectForRoleRoute(role: role, matchedLocation: location),
            defaultRouteForRole(role),
            reason: '$role $location',
          );
        }
      }
    });

    test(
      'the router redirect allows platform owners and administrators',
      () async {
        for (final role in [UserRole.platformOwner, UserRole.platformAdmin]) {
          expect(
            await _redirectFor(role, AppRoutes.platformPlans),
            isNull,
            reason: role.name,
          );
        }
      },
    );

    test(
      'the router redirect keeps organization admins and employees out',
      () async {
        for (final role in [UserRole.orgAdmin, UserRole.employee]) {
          expect(
            await _redirectFor(role, AppRoutes.platformPlans),
            defaultRouteForRole(role),
            reason: role.name,
          );
          expect(
            await _redirectFor(role, AppRoutes.platformPlansAdd),
            defaultRouteForRole(role),
            reason: role.name,
          );
        }
      },
    );
  });

  group('router', () {
    test('the plan routes register with the app router', () {
      final authController = AuthController(
        authRepository: MockAuthenticationRepository(delay: Duration.zero),
      );
      final accessController = AccessController(
        accessRepository: MockAccessRepository(delay: Duration.zero),
      );
      final branchController = BranchContextController();
      addTearDown(() {
        authController.dispose();
        accessController.dispose();
        branchController.dispose();
      });

      late final GoRouter router;
      expect(() {
        router = createAppRouter(
          authController: authController,
          accessController: accessController,
          branchController: branchController,
          initialLocation: AppRoutes.platformPlans,
        );
      }, returnsNormally);
      addTearDown(router.dispose);
    });
  });

  group('shell', () {
    testWidgets('Plans appears in the side navigation on wide layouts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _shell(
          size: const Size(1280, 900),
          destinations: RoleDestinations.platform(isOwner: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plans'), findsOneWidget);
    });

    testWidgets('Plans appears in the navigation drawer on phones', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _shell(
          size: const Size(390, 844),
          destinations: RoleDestinations.platform(isOwner: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(find.text('Plans'), findsOneWidget);
    });
  });
}
