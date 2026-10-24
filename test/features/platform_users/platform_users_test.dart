import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/screens/platform_administrator_details_screen.dart';
import 'package:workaxis/features/platform_users/presentation/screens/platform_administrator_form_screen.dart';
import 'package:workaxis/features/platform_users/presentation/screens/platform_users_list_screen.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_card.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrators_table.dart';

void main() {
  group('Platform Users mock repository and controller', () {
    test('returns typed administrator records and status totals', () async {
      final repository = MockPlatformUsersRepository();
      final controller = PlatformUsersController(repository: repository);

      await controller.loadAdministrators();

      expect(controller.totalCount, 4);
      expect(controller.activeCount, 3);
      expect(controller.suspendedCount, 1);
      expect(controller.administrators.first.fullName, 'David Warner');
      controller.dispose();
    });

    test('filters by username and status', () async {
      final controller = PlatformUsersController(
        repository: MockPlatformUsersRepository(),
      );
      await controller.loadAdministrators();

      controller.setSearchQuery('DPatel');
      expect(controller.administrators.single.fullName, 'Devendra Patel');
      controller.setStatusFilter(AccountStatus.active);
      expect(controller.administrators, isEmpty);
      controller.setSearchQuery('');
      expect(controller.administrators, hasLength(3));

      controller.dispose();
    });

    test('rejects duplicate identifiers across all mock accounts', () async {
      final controller = PlatformUsersController(
        repository: MockPlatformUsersRepository(),
      );
      await controller.loadAdministrators();

      final created = await controller.createAdministrator(
        administrator: PlatformAdministrator(
          id: 'pending',
          fullName: 'Another User',
          username: 'owner',
          email: 'another@workaxis.example',
          status: AccountStatus.active,
          createdAt: DateTime(2026, 10, 17),
        ),
        initialPassword: 'WorkAxis!2026',
      );

      expect(created, isNull);
      expect(controller.totalCount, 4);
      expect(
        controller.actionErrorMessage,
        'That username, email, or phone number is already used by another user.',
      );

      final duplicatePhone = await controller.createAdministrator(
        administrator: PlatformAdministrator(
          id: 'pending-phone',
          fullName: 'Another User',
          username: 'anotheruser',
          email: 'another.user@workaxis.example',
          phone: '+15550003',
          status: AccountStatus.active,
          createdAt: DateTime(2026, 10, 17),
        ),
        initialPassword: 'WorkAxis!2026',
      );
      expect(duplicatePhone, isNull);
      expect(controller.totalCount, 4);

      final duplicatePlatformUsername = await controller.createAdministrator(
        administrator: PlatformAdministrator(
          id: 'pending-profile',
          fullName: 'Another User',
          username: 'DWARNER',
          email: 'another.profile@workaxis.example',
          status: AccountStatus.active,
          createdAt: DateTime(2026, 10, 17),
        ),
        initialPassword: 'WorkAxis!2026',
      );
      expect(duplicatePlatformUsername, isNull);
      expect(controller.totalCount, 4);
      controller.dispose();
    });

    test('creates, updates, suspends and restores a profile', () async {
      final controller = PlatformUsersController(
        repository: MockPlatformUsersRepository(),
      );
      await controller.loadAdministrators();
      final created = await controller.createAdministrator(
        administrator: PlatformAdministrator(
          id: 'pending',
          fullName: 'Jordan Kim',
          username: 'jkim',
          email: 'j.kim@workaxis.example',
          status: AccountStatus.active,
          createdAt: DateTime(2026, 10, 17),
        ),
        initialPassword: 'WorkAxis!2026',
      );

      expect(created, isNotNull);
      expect(controller.totalCount, 5);
      expect(created!.status, AccountStatus.active);

      final updated = await controller.updateAdministrator(
        created.copyWith(fullName: 'Jordan K. Kim'),
      );
      expect(updated?.fullName, 'Jordan K. Kim');

      final suspended = await controller.updateStatus(
        created.id,
        AccountStatus.suspended,
      );
      expect(suspended?.status, AccountStatus.suspended);
      expect(controller.suspendedCount, 2);

      final restored = await controller.updateStatus(
        created.id,
        AccountStatus.active,
      );
      expect(restored?.status, AccountStatus.active);
      expect(controller.suspendedCount, 1);
      controller.dispose();
    });
  });

  testWidgets('phone list uses stacked user cards rather than the table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = PlatformUsersController(
      repository: MockPlatformUsersRepository(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<PlatformUsersController>.value(
        value: controller,
        child: const MaterialApp(home: PlatformUsersListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Platform Users'), findsOneWidget);
    expect(find.byType(PlatformAdministratorCard), findsNWidgets(4));
    expect(find.byType(PlatformAdministratorsTable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet list uses a balanced card grid instead of a table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = PlatformUsersController(
      repository: MockPlatformUsersRepository(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<PlatformUsersController>.value(
        value: controller,
        child: const MaterialApp(home: PlatformUsersListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final firstCard = find.byType(PlatformAdministratorCard).first;
    expect(find.byType(PlatformAdministratorCard), findsNWidgets(4));
    expect(find.byType(PlatformAdministratorsTable), findsNothing);
    expect(tester.getSize(firstCard).width, closeTo(354, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop table fills the available content width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = PlatformUsersController(
      repository: MockPlatformUsersRepository(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<PlatformUsersController>.value(
        value: controller,
        child: const MaterialApp(home: PlatformUsersListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final tableSize = tester.getSize(find.byType(PlatformAdministratorsTable));
    final contentSize = tester.getSize(
      find.byKey(const ValueKey('platform-administrators-table-content')),
    );

    expect(contentSize.width, closeTo(tableSize.width, 1));
    expect(tableSize.width, greaterThan(1060));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add, View, Edit, suspend and restore actions work end to end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = PlatformUsersController(
      repository: MockPlatformUsersRepository(),
    );
    final router = GoRouter(
      initialLocation: AppRoutes.platformUsers,
      routes: [
        GoRoute(
          path: AppRoutes.platformUsers,
          builder: (context, state) => const PlatformUsersListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) =>
                  const PlatformAdministratorFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => PlatformAdministratorDetailsScreen(
                administratorId: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => PlatformAdministratorFormScreen(
                    administratorId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<PlatformUsersController>.value(
        value: controller,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Platform Administrator'));
    await tester.pumpAndSettle();
    expect(find.text('Add Platform Administrator'), findsOneWidget);

    final formFields = find.byType(TextField);
    await tester.enterText(formFields.at(0), 'Jordan Kim');
    await tester.enterText(formFields.at(1), 'jkim');
    await tester.enterText(formFields.at(2), 'j.kim@workaxis.example');
    await tester.enterText(formFields.at(3), '+1 (202) 555-0137');
    await tester.enterText(formFields.at(4), 'WorkAxis!2026');
    await tester.enterText(formFields.at(5), 'WorkAxis!2026');
    await tester.ensureVisible(find.text('Create Administrator'));
    await tester.tap(find.text('Create Administrator'));
    await tester.pumpAndSettle();

    expect(find.byType(PlatformAdministratorDetailsScreen), findsOneWidget);
    expect(find.text('Jordan Kim'), findsWidgets);
    expect(find.text('j.kim@workaxis.example'), findsOneWidget);

    await tester.tap(find.text('Edit Administrator'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Platform Administrator'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Jordan K. Kim');
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Jordan K. Kim'), findsWidgets);

    await tester.tap(find.text('Suspend access'));
    await tester.pumpAndSettle();
    expect(find.text('Suspend access?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Suspend access').last);
    await tester.pumpAndSettle();
    expect(find.text('Suspended'), findsOneWidget);

    await tester.tap(find.text('Restore access'));
    await tester.pumpAndSettle();
    expect(find.text('Restore access?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Restore access').last);
    await tester.pumpAndSettle();
    expect(find.text('Active'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Platform Administrator cannot open the owner-only user route', () {
    expect(
      redirectForRoleRoute(
        role: UserRole.platformAdmin,
        matchedLocation: AppRoutes.platformUsers,
      ),
      AppRoutes.platformWorkspace,
    );
    expect(
      redirectForRoleRoute(
        role: UserRole.platformOwner,
        matchedLocation: AppRoutes.platformUsers,
      ),
      isNull,
    );
  });
}
