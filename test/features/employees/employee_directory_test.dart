import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/employees/presentation/screens/employee_directory_screen.dart';
import 'package:workaxis/features/employees/presentation/screens/organization_member_editor_screen.dart';
import 'package:workaxis/features/employees/presentation/screens/organization_member_form_route.dart';

void main() {
  group('EmployeeDirectoryScreen Widget Tests', () {
    late MockAccessDataSource dataSource;
    late MockAccessRepository accessRepo;
    late MockOrganizationMembersRepository membersRepo;
    late AccessController accessController;
    late BranchContextController branchController;
    late OrganizationMembersController membersController;

    setUp(() async {
      dataSource = MockAccessDataSource();
      accessRepo = MockAccessRepository(
        dataSource: dataSource,
        delay: Duration.zero,
      );
      membersRepo = MockOrganizationMembersRepository(
        accessDataSource: dataSource,
      );

      const adminUser = AppUser(
        id: 'user-oa-01',
        name: 'Jordan Lee',
        username: 'jordan.lee',
        role: UserRole.orgAdmin,
        organizationId: 'org-acme',
      );

      accessController = AccessController(accessRepository: accessRepo);
      await accessController.resolveAccess(adminUser);

      branchController = BranchContextController();
      membersController = OrganizationMembersController(
        repository: membersRepo,
      );
    });

    tearDown(() {
      accessController.dispose();
      branchController.dispose();
      membersController.dispose();
    });

    testWidgets('renders member cards with a details chevron and edit icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accessController),
            ChangeNotifierProvider.value(value: branchController),
            ChangeNotifierProvider.value(value: membersController),
          ],
          child: const MaterialApp(home: EmployeeDirectoryScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Employee Directory'), findsOneWidget);
      expect(find.text('View details'), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
      // Organization Admin may manage every non-platform account.
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('seeds the search field from the controller query', (
      tester,
    ) async {
      final zeroDebounce = OrganizationMembersController(
        repository: membersRepo,
        searchDebounce: Duration.zero,
      );
      addTearDown(zeroDebounce.dispose);
      await zeroDebounce.setQuery(
        access: accessController.accessContext!,
        query: 'sarah',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accessController),
            ChangeNotifierProvider.value(value: branchController),
            ChangeNotifierProvider.value(value: zeroDebounce),
          ],
          child: const MaterialApp(home: EmployeeDirectoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, 'sarah');
    });
    testWidgets('renders cleanly on smartphone (390x844) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accessController),
            ChangeNotifierProvider.value(value: branchController),
            ChangeNotifierProvider.value(value: membersController),
          ],
          child: const MaterialApp(home: EmployeeDirectoryScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Employee Directory'), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet (768x1024) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accessController),
            ChangeNotifierProvider.value(value: branchController),
            ChangeNotifierProvider.value(value: membersController),
          ],
          child: const MaterialApp(home: EmployeeDirectoryScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Employee Directory'), findsOneWidget);
    });

    testWidgets(
      'newly created branch appears in member editor without re-login',
      (tester) async {
        final router = GoRouter(
          initialLocation: AppRoutes.orgAdminEmployees,
          routes: [
            GoRoute(
              path: AppRoutes.orgAdminEmployees,
              builder: (context, state) => const EmployeeDirectoryScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) =>
                      const OrganizationMemberFormRoute(
                        listRoute: AppRoutes.orgAdminEmployees,
                        listLabel: 'Employee Directory',
                      ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: accessController),
              ChangeNotifierProvider.value(value: branchController),
              ChangeNotifierProvider.value(value: membersController),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Dynamically add a new branch to the data source (simulating branch creation)
        const newBranch = BranchSummary(
          id: 'br-newly-created',
          organizationId: 'org-acme',
          name: 'Westside Supercentre',
          code: 'BR-999',
          location: 'West Ring Road',
        );
        dataSource.saveBranch(newBranch);

        // Open the member editor by clicking "Add Member"
        expect(find.text('Add Member'), findsOneWidget);
        await tester.tap(find.text('Add Member'));
        await tester.pumpAndSettle();

        expect(find.byType(OrganizationMemberEditorScreen), findsOneWidget);
        await tester.dragUntilVisible(
          find.text('Westside Supercentre'),
          find.byType(Scrollable).first,
          const Offset(0, -200),
        );
        expect(find.text('Westside Supercentre'), findsOneWidget);
      },
    );
  });
}
