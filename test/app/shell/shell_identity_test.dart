import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/session/session_controller.dart';
import 'package:workaxis/app/shell/adaptive_app_shell.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

import '../../helpers/session_fakes.dart';

const _destinations = [
  AppNavDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    route: '/home',
  ),
  AppNavDestination(
    label: 'Branches',
    icon: Icons.store_outlined,
    selectedIcon: Icons.store,
    route: '/branches',
  ),
];

void main() {
  late FakeAuthRepository authRepo;
  late AuthController auth;
  late AccessController access;
  late BranchContextController branch;
  late SessionController session;

  setUp(() {
    authRepo = FakeAuthRepository(testUser(UserRole.orgAdmin));
    branch = BranchContextController();
    access = AccessController(
      accessRepository: FakeAccessRepository(
        (user) => UserAccessContext(user: user, organization: testOrganization),
      ),
      onResolved: branch.initFromAccessContext,
    );
    auth = AuthController(authRepository: authRepo);
    session = SessionController(
      auth: auth,
      access: access,
      branch: branch,
      sessionScoped: const [],
    );
  });

  tearDown(() {
    session.dispose();
    auth.dispose();
    access.dispose();
    branch.dispose();
  });

  Future<void> pumpShell(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SessionController>.value(value: session),
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<AccessController>.value(value: access),
          ChangeNotifierProvider<BranchContextController>.value(value: branch),
        ],
        child: const MaterialApp(
          home: AdaptiveAppShell(
            currentRoute: '/home',
            destinations: _destinations,
            child: Text('Body'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const placeholders = [
    'Alex Vance',
    'Platform Administrator',
    'APEX LOGISTICS',
    'Apex Logistics & Freight',
    'HQ-001',
    'Org System Online',
    'v2.4',
    'Acme Corporation',
  ];

  testWidgets('renders no invented identity before access resolves', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(1280, 800));

    for (final text in placeholders) {
      expect(find.textContaining(text), findsNothing, reason: text);
    }

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text('Sign Out'), findsOneWidget);
    for (final text in placeholders) {
      expect(find.textContaining(text), findsNothing, reason: text);
    }
  });

  testWidgets('renders the organization from the access context', (
    tester,
  ) async {
    await auth.signIn(identifier: 'x', password: 'y');
    await access.resolveAccess(auth.currentUser!);

    await pumpShell(tester, size: const Size(1280, 800));

    expect(find.text('Test Org'), findsWidgets);
    expect(find.text('TST'), findsOneWidget);
    expect(find.text('Single Org'), findsOneWidget);
    for (final text in placeholders) {
      expect(find.textContaining(text), findsNothing, reason: text);
    }
  });

  testWidgets('selected navigation item is exposed to semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester, size: const Size(1280, 800));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Home')),
      isSemantics(label: 'Home', isSelected: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Branches')),
      isSemantics(label: 'Branches', isSelected: false, isButton: true),
    );
    handle.dispose();
  });

  testWidgets('sign out through the shell clears the whole session', (
    tester,
  ) async {
    await auth.signIn(identifier: 'x', password: 'y');
    await access.resolveAccess(auth.currentUser!);
    await pumpShell(tester, size: const Size(1280, 800));

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(auth.isAuthenticated, isFalse);
    expect(access.accessContext, isNull);
    expect(authRepo.signOutCalls, 1);
  });
}
