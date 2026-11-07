import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/branch_dashboard/data/mock_branch_dashboard_repository.dart';
import 'package:workaxis/features/branch_dashboard/presentation/controllers/branch_dashboard_controller.dart';
import 'package:workaxis/features/branch_dashboard/presentation/screens/branch_home_screen.dart';

import '../../helpers/access_fixtures.dart';

void main() {
  group('Branch Dashboard Repository & Controller', () {
    test(
      'MockBranchDashboardRepository scopes data to the assigned branch',
      () async {
        final repo = MockBranchDashboardRepository(delay: Duration.zero);
        final access = branchManagerAccess(branchIds: ['br-01', 'br-02']);

        final first = await repo.getBranchDashboardSummary(
          access: access,
          branchId: 'br-01',
        );
        final second = await repo.getBranchDashboardSummary(
          access: access,
          branchId: 'br-02',
        );

        expect(first.branchName, equals('Downtown Flagship'));
        expect(second.branchName, equals('Westside Hub'));
        expect(first.branchId, isNot(equals(second.branchId)));
      },
    );

    test('mock repository never falls back to another branch', () async {
      final repo = MockBranchDashboardRepository(delay: Duration.zero);
      final access = branchManagerAccess(branchIds: ['br-01']);

      expect(
        () => repo.getBranchDashboardSummary(access: access, branchId: 'br-04'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('mock repository rejects employees', () async {
      final repo = MockBranchDashboardRepository(delay: Duration.zero);

      expect(
        () => repo.getBranchDashboardSummary(
          access: employeeAccess(),
          branchId: 'br-01',
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('BranchDashboardController reloads and clears previous branch data on change', () async {
      final repo = MockBranchDashboardRepository(delay: Duration.zero);
      final controller = BranchDashboardController(repository: repo);
      final access = branchManagerAccess(branchIds: ['br-01', 'br-02']);

      await controller.loadDashboard(access: access, branchId: 'br-01');
      expect(controller.loadedBranchId, equals('br-01'));
      expect(controller.summary?.branchName, equals('Downtown Flagship'));

      // Switch to another branch
      await controller.loadDashboard(access: access, branchId: 'br-02');
      expect(controller.loadedBranchId, equals('br-02'));
      expect(controller.summary?.branchName, equals('Westside Hub'));
    });
  });

  group('BranchHomeScreen Widget Tests', () {
    testWidgets(
      'renders active branch context and handles multi-branch manager',
      (tester) async {
        final repo = MockBranchDashboardRepository(delay: Duration.zero);
        final dashboardController = BranchDashboardController(repository: repo);

        final branchController = BranchContextController();
        final accessController = AccessController(
          accessRepository: MockAccessRepository(delay: Duration.zero),
        );

        // Setup multi-branch manager access context
        const user = AppUser(
          id: 'user-bm-multi-01',
          name: 'Marcus Chen',
          username: 'manager_multi',
          role: UserRole.branchManager,
          organizationId: 'org-acme',
        );
        await accessController.resolveAccess(user);
        branchController.initFromAccessContext(accessController.accessContext!);

        // Select Downtown Flagship branch
        final dtBranch = accessController.accessContext!.assignedBranches
            .firstWhere((b) => b.id == 'br-01');
        branchController.selectBranch(dtBranch);
        await dashboardController.loadDashboard(
          access: accessController.accessContext!,
          branchId: 'br-01',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<AccessController>.value(
                  value: accessController,
                ),
                ChangeNotifierProvider<BranchContextController>.value(
                  value: branchController,
                ),
                ChangeNotifierProvider<BranchDashboardController>.value(
                  value: dashboardController,
                ),
              ],
              child: const BranchHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify active branch name and code badge
        expect(find.text('Downtown Flagship'), findsOneWidget);
        expect(find.text('BR-101'), findsOneWidget);

        // Verify "Change" action exists because manager has multiple assigned branches
        expect(find.textContaining('Change'), findsOneWidget);
        expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

        // Verify branch-scoped attendance metrics
        expect(find.text("Today's Attendance"), findsOneWidget);
        expect(find.text('Needs Attention'), findsOneWidget);
      },
    );

    testWidgets('renders cleanly on smartphone (390x844)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockBranchDashboardRepository(delay: Duration.zero);
      final dashboardController = BranchDashboardController(repository: repo);
      final branchController = BranchContextController();
      final accessController = AccessController(
        accessRepository: MockAccessRepository(delay: Duration.zero),
      );

      const user = AppUser(
        id: 'user-bm-multi-01',
        name: 'Marcus Chen',
        username: 'manager_multi',
        role: UserRole.branchManager,
        organizationId: 'org-acme',
      );
      await accessController.resolveAccess(user);
      branchController.initFromAccessContext(accessController.accessContext!);
      final dtBranch = accessController.accessContext!.assignedBranches
          .firstWhere((b) => b.id == 'br-01');
      branchController.selectBranch(dtBranch);
      await dashboardController.loadDashboard(
        access: accessController.accessContext!,
        branchId: 'br-01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AccessController>.value(
                value: accessController,
              ),
              ChangeNotifierProvider<BranchContextController>.value(
                value: branchController,
              ),
              ChangeNotifierProvider<BranchDashboardController>.value(
                value: dashboardController,
              ),
            ],
            child: const BranchHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Downtown Flagship'), findsOneWidget);
      expect(find.text("Today's Attendance"), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet (768x1024)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockBranchDashboardRepository(delay: Duration.zero);
      final dashboardController = BranchDashboardController(repository: repo);
      final branchController = BranchContextController();
      final accessController = AccessController(
        accessRepository: MockAccessRepository(delay: Duration.zero),
      );

      const user = AppUser(
        id: 'user-bm-multi-01',
        name: 'Marcus Chen',
        username: 'manager_multi',
        role: UserRole.branchManager,
        organizationId: 'org-acme',
      );
      await accessController.resolveAccess(user);
      branchController.initFromAccessContext(accessController.accessContext!);
      final dtBranch = accessController.accessContext!.assignedBranches
          .firstWhere((b) => b.id == 'br-01');
      branchController.selectBranch(dtBranch);
      await dashboardController.loadDashboard(
        access: accessController.accessContext!,
        branchId: 'br-01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AccessController>.value(
                value: accessController,
              ),
              ChangeNotifierProvider<BranchContextController>.value(
                value: branchController,
              ),
              ChangeNotifierProvider<BranchDashboardController>.value(
                value: dashboardController,
              ),
            ],
            child: const BranchHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Downtown Flagship'), findsOneWidget);
      expect(find.text("Today's Attendance"), findsOneWidget);
    });
  });
}
