import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:workaxis/features/employees/presentation/screens/employee_directory_screen.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/organization_member_card.dart';

void main() {
  testWidgets(
    'tapping an employee tile opens details and the breadcrumb returns to the directory',
    (tester) async {
      final dataSource = MockAccessDataSource();
      final accessController = AccessController(
        accessRepository: MockAccessRepository(
          dataSource: dataSource,
          delay: Duration.zero,
        ),
      );
      await accessController.resolveAccess(
        const AppUser(
          id: 'user-oa-01',
          name: 'Jordan Lee',
          username: 'jordan.lee',
          role: UserRole.orgAdmin,
          organizationId: 'org-acme',
        ),
      );
      final branchController = BranchContextController();
      final membersController = OrganizationMembersController(
        repository: MockOrganizationMembersRepository(
          accessDataSource: dataSource,
        ),
      );
      final router = GoRouter(
        initialLocation: AppRoutes.orgAdminEmployees,
        routes: [
          GoRoute(
            path: AppRoutes.orgAdminEmployees,
            builder: (context, state) => const EmployeeDirectoryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => EmployeeDetailsScreen(
                  memberId: state.pathParameters['id'] ?? '',
                  listRoute: AppRoutes.orgAdminEmployees,
                  listLabel: 'Employee Directory',
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(() {
        router.dispose();
        accessController.dispose();
        branchController.dispose();
        membersController.dispose();
      });

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

      await tester.tap(find.byType(OrganizationMemberCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Employee details'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(PageBreadcrumb),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Employee details'), findsNothing);
      expect(find.byType(OrganizationMemberCard), findsWidgets);
    },
  );
}
