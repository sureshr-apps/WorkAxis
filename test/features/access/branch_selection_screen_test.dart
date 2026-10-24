import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/access/presentation/screens/branch_selection_screen.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

void main() {
  late MockAuthRepositoryStub authRepo;
  late MockAccessRepository accessRepo;
  late MockAccessDataSource accessDataSource;

  late AuthController authController;
  late AccessController accessController;
  late BranchContextController branchController;

  setUp(() {
    authRepo = MockAuthRepositoryStub();
    accessRepo = MockAccessRepository(delay: Duration.zero);
    accessDataSource = MockAccessDataSource();

    authController = AuthController(authRepository: authRepo);
    accessController = AccessController(accessRepository: accessRepo);
    branchController = BranchContextController();

    // Setup Marcus Chen with 3 branches
    final branches = accessDataSource.getAssignedBranchesForUser(
      'user-bm-multi-01',
    );
    final accessContext = UserAccessContext(
      user: const AppUser(
        id: 'user-bm-multi-01',
        name: 'Marcus Chen',
        username: 'manager_multi',
        role: UserRole.branchManager,
        organizationId: 'org-acme',
      ),
      assignedBranches: branches,
    );
    branchController.initFromAccessContext(accessContext);
  });

  tearDown(() {
    authController.dispose();
    accessController.dispose();
    branchController.dispose();
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const BranchSelectionScreen(),
        ),
        GoRoute(
          path: '/branch-manager',
          builder: (context, state) =>
              const Scaffold(body: Text('Branch Manager Workspace')),
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

  group('BranchSelectionScreen Widget Tests', () {
    testWidgets('renders header and all assigned branches', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Select Branch'), findsOneWidget);
      expect(find.text('Downtown Flagship'), findsOneWidget);
      expect(find.text('Westside Hub'), findsOneWidget);
      expect(find.text('North Logistics Center'), findsOneWidget);
      expect(find.text('3 branches available'), findsOneWidget);
    });

    testWidgets('filters branches using search input', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Search for Westside
      await tester.enterText(find.byType(TextField), 'Westside');
      await tester.pumpAndSettle();

      expect(find.text('Westside Hub'), findsOneWidget);
      expect(find.text('Downtown Flagship'), findsNothing);
      expect(find.text('1 branch available'), findsOneWidget);
    });

    testWidgets('selects active branch and updates controller', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap on Downtown Flagship
      await tester.tap(find.text('Downtown Flagship'));
      await tester.pumpAndSettle();

      expect(branchController.hasActiveBranch, isTrue);
      expect(branchController.activeBranch?.branchName, 'Downtown Flagship');
      expect(branchController.activeBranch?.branchCode, 'BR-101');
    });

    testWidgets('cannot select inactive maintenance branch', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap on North Logistics Center (inactive)
      await tester.tap(find.text('North Logistics Center'));
      await tester.pumpAndSettle();

      expect(branchController.hasActiveBranch, isFalse);
    });

    testWidgets('renders cleanly on smartphone (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Select Branch'), findsOneWidget);
      expect(find.text('Downtown Flagship'), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet (768x1024) without overflow', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Select Branch'), findsOneWidget);
      expect(find.text('Downtown Flagship'), findsOneWidget);
    });
  });
}

class MockAuthRepositoryStub extends MockAuthenticationRepository {
  MockAuthRepositoryStub() : super(delay: Duration.zero);
}
