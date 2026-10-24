import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/access/presentation/screens/access_verification_screen.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

void main() {
  late MockAuthenticationRepository authRepo;
  late MockAccessRepository accessRepo;
  late AuthController authController;
  late AccessController accessController;
  late BranchContextController branchController;

  setUp(() {
    authRepo = MockAuthenticationRepository(delay: Duration.zero);
    accessRepo = MockAccessRepository(delay: Duration.zero);
    authController = AuthController(authRepository: authRepo);
    accessController = AccessController(accessRepository: accessRepo);
    branchController = BranchContextController();
  });

  tearDown(() {
    authController.dispose();
    accessController.dispose();
    branchController.dispose();
    authRepo.dispose();
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AccessVerificationScreen(),
        ),
        GoRoute(
          path: '/signin',
          builder: (context, state) =>
              const Scaffold(body: Text('Sign In Screen')),
        ),
        GoRoute(
          path: '/platform',
          builder: (context, state) =>
              const Scaffold(body: Text('Platform Workspace')),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<AccessController>.value(value: accessController),
        ChangeNotifierProvider<BranchContextController>.value(
          value: branchController,
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  group('AccessVerificationScreen Widget Tests', () {
    testWidgets('shows loading state while resolving access', (tester) async {
      // Use small delay to capture verifying state
      accessRepo = MockAccessRepository(delay: const Duration(seconds: 1));
      accessController = AccessController(accessRepository: accessRepo);

      await authController.signIn(
        identifier: 'owner',
        password: 'Password123!',
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Setting up your workspace'), findsOneWidget);
      expect(find.text('Checking your account and access...'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('displays error state with retry and sign-out options', (
      tester,
    ) async {
      accessRepo.shouldSimulateFailure = true;

      await authController.signIn(
        identifier: 'owner',
        password: 'Password123!',
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text("We couldn't verify your access"), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Now disable failure and tap Try Again
      accessRepo.shouldSimulateFailure = false;
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Platform Workspace'), findsOneWidget);
    });
  });
}
