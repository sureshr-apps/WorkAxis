import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access_control/data/datasources/access_remote_data_source.dart';
import 'package:workaxis/features/access_control/data/repositories/access_repository_impl.dart';
import 'package:workaxis/features/access_control/domain/entities/user_role.dart';
import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

void main() {
  late InMemoryAccessDataSource dataSource;
  late AccessRepositoryImpl repository;
  late OrganizationContextController controller;

  setUp(() {
    dataSource = InMemoryAccessDataSource();
    repository = AccessRepositoryImpl(remoteDataSource: dataSource);
    controller = OrganizationContextController(accessRepository: repository);
  });

  tearDown(() {
    controller.dispose();
  });

  group('Access Resolution & Organization Selection', () {
    test('unknown user resolves to AccessDeniedState', () async {
      const authUser = AuthUser(
        uid: 'unknown_001',
        phoneNumber: '+15550000000',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<AccessDeniedState>());
    });

    test('disabled user resolves to AccountDisabledState', () async {
      const authUser = AuthUser(
        uid: 'disabled_001',
        phoneNumber: '+15554567890',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<AccountDisabledState>());
    });

    test(
        'single organization employee automatically skips selection to AccessGrantedState',
        () async {
      const authUser = AuthUser(
        uid: 'jordan_001',
        phoneNumber: '+15552345678',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<AccessGrantedState>());

      final granted = controller.state as AccessGrantedState;
      expect(
          granted.activeMembership.organization.name, 'Central Valley Produce');
      expect(granted.activeMembership.role, UserRole.employee);
      expect(granted.activeMembership.branchName, 'North Packhouse #12');
    });

    test(
        'multiple organizations user routes to OrganizationSelectionRequiredState',
        () async {
      const authUser = AuthUser(
        uid: 'alex_001',
        phoneNumber: '+15551234567',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<OrganizationSelectionRequiredState>());

      final selectionState =
          controller.state as OrganizationSelectionRequiredState;
      expect(selectionState.memberships.length, 3);
    });

    test(
        'employee without assigned branch routes to BranchAssignmentRequiredState',
        () async {
      const authUser = AuthUser(
        uid: 'sam_001',
        phoneNumber: '+15553456789',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<BranchAssignmentRequiredState>());

      final branchReq = controller.state as BranchAssignmentRequiredState;
      expect(branchReq.membership.branchId, isNull);
    });

    test('user with suspended org only routes to OrganizationUnavailableState',
        () async {
      const authUser = AuthUser(
        uid: 'pat_001',
        phoneNumber: '+15558901234',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<OrganizationUnavailableState>());
    });

    test('user with valid pending invitation routes to PendingInvitationState',
        () async {
      const authUser = AuthUser(
        uid: 'invite_user_001',
        phoneNumber: '+15556789012',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<PendingInvitationState>());
    });

    test('user with expired invitation routes to InvitationExpiredState',
        () async {
      const authUser = AuthUser(
        uid: 'invite_expired_001',
        phoneNumber: '+15557890123',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<InvitationExpiredState>());
    });
  });
}
