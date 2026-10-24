import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/authentication/presentation/screens/sign_in_screen.dart';

void main() {
  late MockAuthenticationRepository authRepository;
  late AuthController authController;

  setUp(() {
    authRepository = MockAuthenticationRepository(delay: Duration.zero);
    authController = AuthController(authRepository: authRepository);
  });

  tearDown(() {
    authController.dispose();
    authRepository.dispose();
  });

  Widget createWidgetUnderTest({Size? screenSize}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SignInScreen()),
        GoRoute(
          path: '/verify-access',
          builder: (context, state) =>
              const Scaffold(body: Text('Verify Access Page')),
        ),
      ],
    );

    Widget app = MaterialApp.router(theme: AppTheme.light, routerConfig: router);
    if (screenSize != null) {
      app = MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: app,
      );
    }

    return ChangeNotifierProvider<AuthController>.value(
      value: authController,
      child: app,
    );
  }

  group('SignInScreen Widget Tests', () {
    testWidgets('renders WorkAxis branding and required inputs', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('WorkAxis'), findsOneWidget);
      expect(find.text('Username, email, or phone number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(
        find.text('Forgot your password? Contact your administrator.'),
        findsOneWidget,
      );
    });

    testWidgets('validates required fields on empty submit', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap Sign In without filling in inputs
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(
        find.text('Please enter both your identifier and password.'),
        findsOneWidget,
      );
    });

    testWidgets('displays error banner when authentication fails', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter invalid credentials
      await tester.enterText(
        find.widgetWithText(TextField, '').first,
        'wrong_user',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '').last,
        'wrong_password',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Invalid username, email, or password.'),
        findsOneWidget,
      );
    });

    testWidgets('authenticates successfully with valid credentials', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid credentials
      await tester.enterText(find.widgetWithText(TextField, '').first, 'owner');
      await tester.enterText(
        find.widgetWithText(TextField, '').last,
        'Password123!',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(authController.isAuthenticated, isTrue);
      expect(authController.currentUser?.username, 'owner');
    });

    testWidgets('renders desktop split-screen hero panel on wide screens', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createWidgetUnderTest(screenSize: const Size(1280, 800)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Unified Operations &\nMulti-Branch Governance'),
        findsOneWidget,
      );
      expect(find.text('Multi-Branch Fleet Topology'), findsOneWidget);
      expect(find.text('Zero-Trust Scoped Access'), findsOneWidget);
      expect(find.text('Sub-Second Roster Telemetry'), findsOneWidget);
      expect(find.text('QUICK-FILL TEST ACCOUNTS'), findsOneWidget);
    });

    testWidgets('quick-fills demo credentials when chip is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final platformOwnerChip = find.text('Platform Owner');
      await tester.ensureVisible(platformOwnerChip);
      await tester.tap(platformOwnerChip);
      await tester.pumpAndSettle();

      expect(find.text('owner'), findsOneWidget);
    });
  });
}
