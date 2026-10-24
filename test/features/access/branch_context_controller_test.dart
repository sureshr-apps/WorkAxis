import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

void main() {
  late BranchContextController controller;
  late MockAccessDataSource dataSource;

  setUp(() {
    controller = BranchContextController();
    dataSource = MockAccessDataSource();
  });

  tearDown(() {
    controller.dispose();
  });

  group('BranchContextController', () {
    test('initializes active branch from single-branch access context', () {
      final branches = dataSource.getAssignedBranchesForUser(
        'user-bm-single-01',
      );
      final context = UserAccessContext(
        user: const AppUser(
          id: 'user-bm-single-01',
          name: 'Sophia Patel',
          username: 'manager_single',
          role: UserRole.branchManager,
          organizationId: 'org-acme',
        ),
        assignedBranches: branches,
      );

      controller.initFromAccessContext(context);

      expect(controller.hasActiveBranch, isFalse);
      expect(controller.assignedBranches.length, 1);
    });

    test(
      'selectBranch sets active branch for valid assigned active branch',
      () {
        final branches = dataSource.getAssignedBranchesForUser(
          'user-bm-multi-01',
        );
        final context = UserAccessContext(
          user: const AppUser(
            id: 'user-bm-multi-01',
            name: 'Marcus Chen',
            username: 'manager_multi',
            role: UserRole.branchManager,
            organizationId: 'org-acme',
          ),
          assignedBranches: branches,
        );

        controller.initFromAccessContext(context);

        final branchToSelect = branches.firstWhere((b) => b.id == 'br-01');
        final success = controller.selectBranch(branchToSelect);

        expect(success, isTrue);
        expect(controller.hasActiveBranch, isTrue);
        expect(controller.activeBranch?.branchId, 'br-01');
        expect(controller.activeBranch?.branchName, 'Downtown Flagship');
        expect(controller.activeBranch?.branchCode, 'BR-101');
      },
    );

    test('rejects selecting unassigned branch', () {
      final branches = dataSource.getAssignedBranchesForUser(
        'user-bm-multi-01',
      );
      final context = UserAccessContext(
        user: const AppUser(
          id: 'user-bm-multi-01',
          name: 'Marcus Chen',
          username: 'manager_multi',
          role: UserRole.branchManager,
          organizationId: 'org-acme',
        ),
        assignedBranches: branches,
      );

      controller.initFromAccessContext(context);

      const unassignedBranch = BranchSummary(
        id: 'br-999',
        organizationId: 'org-other',
        name: 'Unauthorized Branch',
        code: 'BR-999',
        location: 'Nowhere',
      );

      final success = controller.selectBranch(unassignedBranch);
      expect(success, isFalse);
      expect(controller.hasActiveBranch, isFalse);
    });

    test('rejects selecting inactive branch', () {
      final branches = dataSource.getAssignedBranchesForUser(
        'user-bm-multi-01',
      );
      final context = UserAccessContext(
        user: const AppUser(
          id: 'user-bm-multi-01',
          name: 'Marcus Chen',
          username: 'manager_multi',
          role: UserRole.branchManager,
          organizationId: 'org-acme',
        ),
        assignedBranches: branches,
      );

      controller.initFromAccessContext(context);

      final inactiveBranch = branches.firstWhere((b) => b.id == 'br-03');
      expect(inactiveBranch.isActive, isFalse);

      final success = controller.selectBranch(inactiveBranch);
      expect(success, isFalse);
      expect(controller.hasActiveBranch, isFalse);
    });

    test('clear resets active branch and assigned branches', () {
      final branches = dataSource.getAssignedBranchesForUser(
        'user-bm-multi-01',
      );
      final context = UserAccessContext(
        user: const AppUser(
          id: 'user-bm-multi-01',
          name: 'Marcus Chen',
          username: 'manager_multi',
          role: UserRole.branchManager,
          organizationId: 'org-acme',
        ),
        assignedBranches: branches,
      );

      controller.initFromAccessContext(context);
      controller.selectBranch(branches.firstWhere((b) => b.id == 'br-01'));
      expect(controller.hasActiveBranch, isTrue);

      controller.clear();
      expect(controller.hasActiveBranch, isFalse);
      expect(controller.assignedBranches, isEmpty);
    });
  });
}
