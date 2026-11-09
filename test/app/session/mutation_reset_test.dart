import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/branches/data/mock_branch_management_repository.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/presentation/controllers/branch_management_controller.dart';
import 'package:workaxis/features/settings/data/mock_settings_repository.dart';
import 'package:workaxis/features/settings/domain/models/organization_settings.dart';
import 'package:workaxis/features/settings/domain/models/platform_settings.dart';
import 'package:workaxis/features/settings/presentation/controllers/settings_controller.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/session_fakes.dart';

class _DelayedBranch extends MockBranchManagementRepository {
  final saved = Completer<BranchRecord>();
  @override
  Future<BranchRecord> saveBranch({
    required UserAccessContext access,
    required BranchRecord branch,
  }) => saved.future;
}

class _DelayedSettings extends MockSettingsRepository {
  final organization = Completer<OrganizationSettings>();
  final platform = Completer<PlatformSettings>();
  @override
  Future<OrganizationSettings> saveOrganizationSettings({
    required UserAccessContext access,
    required OrganizationSettings settings,
  }) => organization.future;
  @override
  Future<PlatformSettings> savePlatformSettings({
    required UserAccessContext access,
    required PlatformSettings settings,
  }) => platform.future;
}

class _DelayedAuth extends FakeAuthRepository {
  _DelayedAuth() : super(null);
  final restored = Completer<AppUser?>();
  @override
  Future<AppUser?> getCurrentUser() => restored.future;
}

void main() {
  for (final fails in [false, true]) {
    test(
      'branch mutation ${fails ? "failure" : "completion"} after reset cannot refill state',
      () async {
        final repo = _DelayedBranch();
        final controller = BranchManagementController(repository: repo);
        addTearDown(controller.dispose);
        final access = orgAdminAccess();
        final branch = (await repo.getBranches(access)).first;
        final pending = controller.saveBranch(access: access, branch: branch);
        controller.reset();
        if (fails) {
          repo.saved.completeError(StateError('old session'));
        } else {
          repo.saved.complete(branch);
        }
        expect(await pending, isNull);
        expect(controller.branches, isEmpty);
        expect(controller.actionErrorMessage, isNull);
        expect(controller.isSaving, isFalse);
      },
    );
  }
  test('organization and platform settings completions cannot restore cleared data', () async {
    final repo = _DelayedSettings();
    final controller = SettingsController(repository: repo);
    addTearDown(controller.dispose);
    final org = controller.saveOrganization(
      access: orgAdminAccess(),
      settings: OrganizationSettings.defaults,
    );
    controller.reset();
    repo.organization.complete(OrganizationSettings.defaults);
    expect(await org, isFalse);
    expect(controller.organizationSettings, isNull);
    final platform = controller.savePlatform(
      access: platformAccess(),
      settings: PlatformSettings.defaults,
    );
    controller.reset();
    repo.platform.complete(PlatformSettings.defaults);
    expect(await platform, isFalse);
    expect(controller.platformSettings, isNull);
  });
  test(
    'auth restoration does not subscribe after controller disposal',
    () async {
      final repo = _DelayedAuth();
      final controller = AuthController(authRepository: repo);
      final pending = controller.init();
      controller.dispose();
      repo.restored.complete(null);
      await pending;
      expect(repo.states.hasListener, isFalse);
      await repo.states.close();
    },
  );
}
