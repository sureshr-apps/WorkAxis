import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/sql_connect_access_repository.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

void main() {
  group('SqlConnectAccessRepository Tests', () {
    late SqlConnectAccessRepository repository;

    setUp(() {
      repository = SqlConnectAccessRepository();
    });

    test('resolveCurrentUserAccess resolves platform owner access context correctly without org requirement', () async {
      const platformOwner = AppUser(
        id: 'usr-po-1',
        name: 'Chief Admin',
        username: 'admin',
        role: UserRole.platformOwner,
        status: AccountStatus.active,
      );

      final access = await repository.resolveCurrentUserAccess(platformOwner);

      expect(access.user.id, equals('usr-po-1'));
      expect(access.organization, isNull);
      expect(access.assignedBranches, isEmpty);
      expect(access.activeBranch, isNull);
      expect(access.permissions, contains('platform.manage'));
      expect(access.permissions, contains('platform.owner'));
    });

    test('resolveCurrentUserAccess resolves platform admin access context correctly without org requirement', () async {
      const platformAdmin = AppUser(
        id: 'usr-pa-1',
        name: 'Operations Admin',
        username: 'ops_admin',
        role: UserRole.platformAdmin,
        status: AccountStatus.active,
      );

      final access = await repository.resolveCurrentUserAccess(platformAdmin);

      expect(access.user.id, equals('usr-pa-1'));
      expect(access.organization, isNull);
      expect(access.assignedBranches, isEmpty);
      expect(access.activeBranch, isNull);
      expect(access.permissions, contains('platform.manage'));
      expect(access.permissions, isNot(contains('platform.owner')));
    });

    test('resolveCurrentUserAccess throws AccessResolutionException when customer user has no organizationId', () async {
      const customerUserWithoutOrg = AppUser(
        id: 'usr-oa-1',
        name: 'Unassigned Admin',
        username: 'unassigned',
        role: UserRole.orgAdmin,
        status: AccountStatus.active,
        organizationId: null,
      );

      expect(
        () => repository.resolveCurrentUserAccess(customerUserWithoutOrg),
        throwsA(isA<AccessResolutionException>()),
      );
    });

    test('validateBranchAccess returns false when user has no assigned branches', () async {
      final isValid = await repository.validateBranchAccess(
        userId: 'usr-none',
        branchId: 'non-existent-branch',
      );
      expect(isValid, isFalse);
    });
  });
}
