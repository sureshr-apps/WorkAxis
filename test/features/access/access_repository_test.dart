import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/authentication/data/mock_auth_data_source.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

void main() {
  late MockAccessRepository accessRepository;
  late MockAuthDataSource authDataSource;

  setUp(() {
    accessRepository = MockAccessRepository(delay: Duration.zero);
    authDataSource = MockAuthDataSource();
  });

  group('AccessRepository - Role Resolution', () {
    test(
      'resolves Platform Owner without customer organization context',
      () async {
        final user = authDataSource.findById('user-po-01')!;
        final context = await accessRepository.resolveCurrentUserAccess(user);

        expect(context.user.role, UserRole.platformOwner);
        expect(context.organization, isNull);
        expect(context.assignedBranches, isEmpty);
        expect(context.requiresBranchSelection, isFalse);
        expect(context.permissions.contains('platform.owner'), isTrue);
      },
    );

    test(
      'resolves Platform Administrator without customer organization context',
      () async {
        final user = authDataSource.findById('user-pa-01')!;
        final context = await accessRepository.resolveCurrentUserAccess(user);

        expect(context.user.role, UserRole.platformAdmin);
        expect(context.organization, isNull);
        expect(context.assignedBranches, isEmpty);
        expect(context.requiresBranchSelection, isFalse);
      },
    );

    test(
      'resolves Organization Admin with single customer organization',
      () async {
        final user = authDataSource.findById('user-oa-01')!;
        final context = await accessRepository.resolveCurrentUserAccess(user);

        expect(context.user.role, UserRole.orgAdmin);
        expect(context.organization, isNotNull);
        expect(context.organization?.id, 'org-acme');
        expect(context.organization?.name, 'Apex Logistics & Freight');
        expect(context.requiresBranchSelection, isFalse);
      },
    );

    test('resolves Employee with organization and assigned branch', () async {
      final user = authDataSource.findById('user-emp-01')!;
      final context = await accessRepository.resolveCurrentUserAccess(user);

      expect(context.user.role, UserRole.employee);
      expect(context.organization?.id, 'org-acme');
      expect(context.assignedBranches.length, 1);
      expect(context.activeBranch?.branchId, 'br-01');
      expect(context.requiresBranchSelection, isFalse);
    });
  });

  group('AccessRepository - Branch Manager Behavior', () {
    test('requires branch selection for Branch Manager with multiple active branches', () async {
      final user = authDataSource.findById('user-bm-multi-01')!;
      final context = await accessRepository.resolveCurrentUserAccess(user);

      expect(context.user.role, UserRole.branchManager);
      expect(context.organization?.id, 'org-acme');
      // Assigned to 3 branches total (2 active, 1 inactive)
      expect(context.assignedBranches.length, 3);
      expect(context.activeAssignedBranches.length, 2);
      expect(context.activeBranch, isNull);
      expect(context.requiresBranchSelection, isTrue);
    });

    test('auto-selects active branch for Branch Manager with single assigned branch', () async {
      final user = authDataSource.findById('user-bm-single-01')!;
      final context = await accessRepository.resolveCurrentUserAccess(user);

      expect(context.user.role, UserRole.branchManager);
      expect(context.organization?.id, 'org-acme');
      expect(context.assignedBranches.length, 1);
      expect(context.hasSingleAssignedBranch, isTrue);
      expect(context.activeBranch, isNotNull);
      expect(context.activeBranch?.branchId, 'br-04');
      expect(context.activeBranch?.branchName, 'East Bay Outlet');
      // Skips branch selection!
      expect(context.requiresBranchSelection, isFalse);
    });

    test('validates branch access correctly', () async {
      final canAccess = await accessRepository.validateBranchAccess(
        userId: 'user-bm-multi-01',
        branchId: 'br-01',
      );
      expect(canAccess, isTrue);

      final cannotAccessUnassigned = await accessRepository
          .validateBranchAccess(
            userId: 'user-bm-multi-01',
            branchId: 'br-04', // East Bay Outlet is not assigned to Marcus
          );
      expect(cannotAccessUnassigned, isFalse);

      final cannotAccessInactive = await accessRepository.validateBranchAccess(
        userId: 'user-bm-multi-01',
        branchId: 'br-03', // North Logistics is inactive
      );
      expect(cannotAccessInactive, isFalse);
    });

    test(
      'throws typed AccessResolutionException when failure is simulated',
      () async {
        accessRepository.shouldSimulateFailure = true;
        final user = authDataSource.findById('user-oa-01')!;

        expect(
          () => accessRepository.resolveCurrentUserAccess(user),
          throwsA(isA<AccessResolutionException>()),
        );
      },
    );
  });
}
