import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/routing/route_error_screen.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/platform_dashboard/presentation/controllers/platform_dashboard_controller.dart';

import '../helpers/test_backend.dart';

void main() {
  testWidgets('sign-in, sign-out and the next user starts from clean state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repos = buildTestBackend();
    addTearDown(mockAuthOf(repos).dispose);

    await tester.pumpWidget(WorkAxisApp(repositories: repos));
    await tester.pumpAndSettle();

    BuildContext appContext() => tester.element(find.byType(Scaffold).first);

    // Sign in as the Platform Owner.
    await tester.enterText(find.byType(TextField).at(0), 'owner');
    await tester.enterText(find.byType(TextField).at(1), 'Password123!');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('PLATFORM CONSOLE'), findsOneWidget);
    expect(
      appContext().read<PlatformDashboardController>().status,
      PlatformDashboardStatus.loaded,
    );
    expect(appContext().read<AccessController>().hasResolved, isTrue);

    // Sign out through the profile menu.
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Username, email, or phone number'), findsOneWidget);
    final context = appContext();
    expect(context.read<AuthController>().isAuthenticated, isFalse);
    expect(context.read<AccessController>().hasResolved, isFalse);
    expect(
      context.read<PlatformDashboardController>().status,
      PlatformDashboardStatus.initial,
    );
    expect(context.read<PlatformDashboardController>().summary, isNull);
  });

  testWidgets('a branch manager with several branches must pick one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repos = buildTestBackend();
    addTearDown(mockAuthOf(repos).dispose);

    await tester.pumpWidget(WorkAxisApp(repositories: repos));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'manager_multi');
    await tester.enterText(find.byType(TextField).at(1), 'Password123!');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Select Branch'), findsOneWidget);
  });

  testWidgets('unknown routes are redirected to sign-in when signed out', (
    tester,
  ) async {
    final repos = buildTestBackend();
    addTearDown(mockAuthOf(repos).dispose);

    await tester.pumpWidget(
      WorkAxisApp(repositories: repos, initialLocation: '/no/such/page'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Username, email, or phone number'), findsOneWidget);
  });

  testWidgets('route error screen offers a way back', (tester) async {
    final router = GoRouter(
      initialLocation: '/missing',
      errorBuilder: (context, state) =>
          RouteErrorScreen(location: state.uri.toString()),
      routes: [
        GoRoute(
          path: AppRoutes.verifyAccess,
          builder: (context, state) => const Text('verify'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
    await tester.tap(find.text('Go to my workspace'));
    await tester.pumpAndSettle();
    expect(find.text('verify'), findsOneWidget);
  });
}
