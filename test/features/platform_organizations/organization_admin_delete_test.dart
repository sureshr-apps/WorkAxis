import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_admin_rules.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';

OrganizationAdminUser _admin(String id, OrganizationAdminStatus status) =>
    OrganizationAdminUser(
      id: id,
      name: 'Admin $id',
      email: '$id@example.com',
      phone: '',
      username: id,
      status: status,
    );

void main() {
  group('OrganizationAdminRules.checkDeletion', () {
    test('refuses to delete the only active administrator', () {
      expect(
        () => OrganizationAdminRules.checkDeletion([
          _admin('a1', OrganizationAdminStatus.active),
        ], 'a1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'allows deleting an active administrator while another stays active',
      () {
        expect(
          () => OrganizationAdminRules.checkDeletion([
            _admin('a1', OrganizationAdminStatus.active),
            _admin('a2', OrganizationAdminStatus.active),
          ], 'a1'),
          returnsNormally,
        );
      },
    );

    test('allows deleting a suspended administrator', () {
      expect(
        () => OrganizationAdminRules.checkDeletion([
          _admin('a1', OrganizationAdminStatus.active),
          _admin('a2', OrganizationAdminStatus.suspended),
        ], 'a2'),
        returnsNormally,
      );
    });
  });

  group('mock repository deletion', () {
    test('removes the administrator from the organization', () async {
      final repository = MockPlatformOrganizationsRepository();
      final page = await repository.getOrganizationsPage();
      final org = page.items.firstWhere((o) => o.admins.length >= 2);
      final victim = org.admins.firstWhere(
        (a) => !OrganizationAdminRules.isLastActiveAdmin(org.admins, a.id),
      );

      final updated = await repository.deleteOrganizationAdmin(
        org.id,
        victim.id,
      );

      expect(updated.admins.any((a) => a.id == victim.id), isFalse);
      expect(updated.admins.length, org.admins.length - 1);
    });

    test('refuses to delete the only active administrator', () async {
      final repository = MockPlatformOrganizationsRepository();
      final org = (await repository.getOrganizationById('org-apex'))!;
      final only = org.admins.firstWhere(
        (a) => a.status == OrganizationAdminStatus.active,
      );

      await expectLater(
        repository.deleteOrganizationAdmin(org.id, only.id),
        throwsA(isA<ValidationException>()),
      );
      final after = await repository.getOrganizationById('org-apex');
      expect(after!.admins.any((a) => a.id == only.id), isTrue);
    });
  });

  group('PlatformOrganizationsController.deleteAdministrator', () {
    test('removes the administrator from the selected organization', () async {
      final repository = MockPlatformOrganizationsRepository();
      final org = (await repository.getOrganizationsPage()).items.firstWhere(
        (o) => o.admins.length >= 2,
      );
      final controller = PlatformOrganizationsController(
        repository: repository,
      );
      addTearDown(controller.dispose);
      await controller.loadOrganizationDetails(org.id);
      final victim = controller.selectedOrganization!.admins.firstWhere(
        (a) => !controller.isLastActiveAdministrator(a.id),
      );

      final ok = await controller.deleteAdministrator(org.id, victim.id);

      expect(ok, isTrue);
      expect(controller.actionErrorMessage, isNull);
      expect(
        controller.selectedOrganization!.admins.any((a) => a.id == victim.id),
        isFalse,
      );
    });

    test('a refused delete reports why and changes nothing', () async {
      final repository = MockPlatformOrganizationsRepository();
      final controller = PlatformOrganizationsController(
        repository: repository,
      );
      addTearDown(controller.dispose);
      await controller.loadOrganizationDetails('org-apex');
      final only = controller.selectedOrganization!.admins.firstWhere(
        (a) => controller.isLastActiveAdministrator(a.id),
      );

      final ok = await controller.deleteAdministrator('org-apex', only.id);

      expect(ok, isFalse);
      expect(
        controller.actionErrorMessage,
        OrganizationAdminRules.lastActiveAdminMessage,
      );
      expect(
        controller.selectedOrganization!.admins.any((a) => a.id == only.id),
        isTrue,
      );
    });
  });
}
