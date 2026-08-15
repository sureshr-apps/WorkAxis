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

  group('Organization Switching & Zero Data Leakage', () {
    test(
        'switching organizations properly clears previous context and switches active membership',
        () async {
      const authUser = AuthUser(
        uid: 'alex_001',
        phoneNumber: '+15551234567',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<OrganizationSelectionRequiredState>());

      final selectionState =
          controller.state as OrganizationSelectionRequiredState;
      final org1 = selectionState.memberships[0]; // Central Valley (Admin)
      final org2 =
          selectionState.memberships[1]; // GreenHarvest (Branch Manager)

      // 1. Select Org 1
      controller.selectOrganization(org1);
      expect(controller.state, isA<AccessGrantedState>());
      var granted = controller.state as AccessGrantedState;
      expect(
          granted.activeMembership.organization.name, 'Central Valley Produce');
      expect(granted.activeMembership.role, UserRole.orgAdmin);
      expect(granted.activeMembership.branchId, isNull);

      // 2. Switch to Org 2
      await controller.switchOrganization(org2);
      expect(controller.state, isA<AccessGrantedState>());
      granted = controller.state as AccessGrantedState;
      expect(granted.activeMembership.organization.name,
          'GreenHarvest Distribution');
      expect(granted.activeMembership.role, UserRole.branchManager);
      expect(granted.activeMembership.branchName, 'Downtown Hub #102');
    });

    test(
        'accepting invitation creates membership and activates organization context',
        () async {
      const authUser = AuthUser(
        uid: 'invite_user_001',
        phoneNumber: '+15556789012',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<PendingInvitationState>());

      final invite = (controller.state as PendingInvitationState).invitation;
      await controller.acceptInvitation(invite.id);

      expect(controller.state, isA<AccessGrantedState>());
      final granted = controller.state as AccessGrantedState;
      expect(
          granted.activeMembership.organization.name, 'Central Valley Produce');
      expect(granted.activeMembership.role, UserRole.branchManager);
      expect(granted.activeMembership.branchName, 'West Gate Facility #08');
    });
  });
}
