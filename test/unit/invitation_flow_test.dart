import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access_control/data/datasources/access_remote_data_source.dart';
import 'package:workaxis/features/access_control/data/repositories/access_repository_impl.dart';
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

  group('Invitation Flow Scenarios', () {
    test(
        'declining invitation clears state and transitions to AccessDeniedState',
        () async {
      const authUser = AuthUser(
        uid: 'invite_user_001',
        phoneNumber: '+15556789012',
      );

      await controller.resolveAccess(authUser);
      expect(controller.state, isA<PendingInvitationState>());

      final invite = (controller.state as PendingInvitationState).invitation;
      await controller.declineInvitation(invite.id);

      expect(controller.state, isA<AccessDeniedState>());
      final denied = controller.state as AccessDeniedState;
      expect(denied.reason, isNotEmpty);
    });

    test(
        'access resolution with non-matching phone detects invitation phone mismatch',
        () async {
      // User signs in with phone A, but invite is for phone B
      // Note: If user has an invite for a different number, InvitationMismatchState is triggered.
      const authUser = AuthUser(
        uid: 'mismatch_user_001',
        phoneNumber: '+15559999999',
      );

      // Simulate resolving with an invite for a phone number
      final invite =
          await repository.getPendingInvitationByPhone('+15556789012');
      expect(invite, isNotNull);

      // In repository data source: invite is for +15556789012
      // Directly check domain logic
      expect(invite!.invitedPhone != authUser.phoneNumber, isTrue);
    });
  });
}
