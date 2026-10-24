import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/shell/adaptive_app_shell.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

void main() {
  group('AdaptiveAppShell Tests', () {
    late AuthController authController;
    late AccessController accessController;
    late BranchContextController branchController;

    const sampleDestinations = [
      AppNavDestination(
        label: 'Home',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        route: '/home',
      ),
      AppNavDestination(
        label: 'Employees',
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        route: '/employees',
      ),
    ];

    setUp(() {
      authController = AuthController(
        authRepository: MockAuthenticationRepository(delay: Duration.zero),
      );
      accessController = AccessController(
        accessRepository: MockAccessRepository(delay: Duration.zero),
      );
      branchController = BranchContextController();
    });

    Widget buildTestShell({required Size size}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: authController),
            ChangeNotifierProvider<AccessController>.value(
              value: accessController,
            ),
            ChangeNotifierProvider<BranchContextController>.value(
              value: branchController,
            ),
          ],
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: const AdaptiveAppShell(
              currentRoute: '/home',
              destinations: sampleDestinations,
              child: Text('Main Body Content'),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'renders profile icon in header row, removes signout from header, and removes profile from side pane on compact (<600dp)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestShell(size: const Size(390, 844)));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byType(NavigationRail), findsNothing);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.text('WorkAxis'), findsOneWidget);
        expect(find.text('Main Body Content'), findsOneWidget);

        // Header row has profile icon and NO standalone logout icon button
        expect(find.byIcon(Icons.person), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsNothing);

        // Open drawer via hamburger button
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Employees'), findsOneWidget);
        // Verify profile and signout are NOT in the drawer side pane
        expect(find.text('Sign Out'), findsNothing);

        // Close drawer
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Tap profile icon in header row to open profile popup menu
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Verify profile popup displays user details and Sign Out action
        expect(find.text('Sign Out'), findsOneWidget);
      },
    );

    testWidgets(
      'renders collapsible side pane and profile icon in header on medium viewport (600–839dp)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(768, 1024));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestShell(size: const Size(768, 1024)));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsNothing);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.text('WorkAxis'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsNothing);
        expect(find.text('Main Body Content'), findsOneWidget);

        // Open drawer via hamburger button
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Employees'), findsOneWidget);
        expect(find.text('Sign Out'), findsNothing);
      },
    );

    testWidgets('renders persistent sidebar on expanded viewport (>=840dp)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestShell(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Ops Hub'), findsOneWidget);
      expect(find.text('Operations Hub'), findsOneWidget);
      expect(find.text('Main Body Content'), findsOneWidget);
    });

    testWidgets('renders top console header with user profile on desktop', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestShell(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('Operations Hub'), findsOneWidget);
      expect(find.text('OPERATIONS CONSOLE'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
