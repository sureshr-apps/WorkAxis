import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';

import '../../helpers/access_fixtures.dart';

class _Members extends MockOrganizationMembersRepository {
  final completion = Completer<OrganizationMember>();
  @override
  Future<OrganizationMember> saveMember({
    required UserAccessContext access,
    required OrganizationMember member,
    required String initialPassword,
    String? activeBranchId,
  }) => completion.future;
}

class _Users extends MockPlatformUsersRepository {
  final completion = Completer<PlatformAdministrator>();
  @override
  Future<PlatformAdministrator> createAdministrator({
    required PlatformAdministrator administrator,
    required String initialPassword,
  }) => completion.future;
}

class _Organizations extends MockPlatformOrganizationsRepository {
  final completion = Completer<CustomerOrganization>();
  @override
  Future<CustomerOrganization> updateOrganization(
    CustomerOrganization organization,
  ) => completion.future;
}

void main() {
  for (final fails in [false, true]) {
    test(
      'member save ${fails ? "failure" : "completion"} cannot restore a reset scope',
      () async {
        final repo = _Members();
        final controller = OrganizationMembersController(repository: repo);
        addTearDown(controller.dispose);
        final member = (await repo.getMembersPage(access: orgAdminAccess()))
            .items
            .first;
        final pending = controller.saveMember(
          access: orgAdminAccess(),
          member: member,
          initialPassword: '',
        );
        controller.reset();
        if (fails) {
          repo.completion.completeError(StateError('old session'));
        } else {
          repo.completion.complete(member);
        }
        expect(await pending, isNull);
        expect(controller.members, isEmpty);
        expect(controller.actionErrorMessage, isNull);
        expect(controller.isSaving, isFalse);
      },
    );
    test(
      'platform account ${fails ? "failure" : "completion"} cannot restore reset data',
      () async {
        final repo = _Users();
        final controller = PlatformUsersController(repository: repo);
        addTearDown(controller.dispose);
        final admin = (await repo.getAdministratorsPage()).items.first;
        final pending = controller.createAdministrator(
          administrator: admin,
          initialPassword: '',
        );
        controller.reset();
        if (fails) {
          repo.completion.completeError(StateError('old session'));
        } else {
          repo.completion.complete(admin);
        }
        expect(await pending, isNull);
        expect(controller.administrators, isEmpty);
        expect(controller.selectedAdministrator, isNull);
        expect(controller.actionErrorMessage, isNull);
      },
    );
    test(
      'organization edit ${fails ? "failure" : "completion"} cannot restore reset data',
      () async {
        final repo = _Organizations();
        final controller = PlatformOrganizationsController(repository: repo);
        addTearDown(controller.dispose);
        final org = (await repo.getOrganizationsPage()).items.first;
        final pending = controller.updateOrganization(org);
        controller.reset();
        if (fails) {
          repo.completion.completeError(StateError('old session'));
        } else {
          repo.completion.complete(org);
        }
        expect(await pending, isNull);
        expect(controller.organizations, isEmpty);
        expect(controller.selectedOrganization, isNull);
        expect(controller.actionErrorMessage, isNull);
      },
    );
  }
}
