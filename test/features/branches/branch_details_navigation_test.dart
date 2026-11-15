import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/branches/data/mock_branch_management_repository.dart';
import 'package:workaxis/features/branches/presentation/controllers/branch_management_controller.dart';
import 'package:workaxis/features/branches/presentation/screens/branch_details_screen.dart';

void main() {
  testWidgets(
    'branch details page shows its profile and the breadcrumb returns to Branch Management',
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
      final branchController = BranchManagementController(
        repository: MockBranchManagementRepository(
          accessDataSource: dataSource,
        ),
      );
      final router = GoRouter(
        initialLocation: '${AppRoutes.orgAdminBranches}/br-01',
        routes: [
          GoRoute(
            path: AppRoutes.orgAdminBranches,
            builder: (context, state) =>
                const Scaffold(body: Text('Branch list')),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => BranchDetailsScreen(
                  branchId: state.pathParameters['id'] ?? '',
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
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accessController),
            ChangeNotifierProvider.value(value: branchController),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Branch details'), findsOneWidget);
      expect(find.text('Branch code'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(PageBreadcrumb),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Branch details'), findsNothing);
      expect(find.text('Branch list'), findsOneWidget);
    },
  );
}
