import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/assets/domain/models/asset_queue.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/assets/domain/repositories/assets_repository.dart';
import 'package:workaxis/features/assets/presentation/controllers/assets_controller.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

import '../../contracts/acme_scenario.dart';

final _asset = EmployeeAsset(
  id: 'asset-1',
  organizationId: 'org-acme',
  branchId: 'br-01',
  branchName: 'Downtown Flagship',
  employeeId: 'user-emp-01',
  employeeName: 'Sarah Connor',
  name: 'Work phone',
  category: 'Device',
  assetTag: 'WA-001',
  status: AssetStatus.assigned,
  acknowledgementRequired: false,
  acknowledgementStatus: AssetAcknowledgementStatus.notRequired,
);

/// Holds every save until the test completes [pendingSave].
class _GatedAssetsRepository implements AssetsRepository {
  final pendingSave = Completer<EmployeeAsset>();

  @override
  Future<EmployeeAsset> saveAsset({
    required UserAccessContext access,
    required EmployeeAsset asset,
    String? activeBranchId,
  }) => pendingSave.future;

  @override
  Future<PageResult<EmployeeAsset>> getAssetsPage({
    required UserAccessContext access,
    required AssetQueue queue,
    String? activeBranchId,
    String? query,
    int offset = 0,
    int limit = defaultPageSize,
  }) async => const PageResult.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoMembers implements OrganizationMembersRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'reloading during a save keeps the saved asset and clears isSaving',
    () async {
      final repository = _GatedAssetsRepository();
      final controller = AssetsController(
        repository: repository,
        membersRepository: _NoMembers(),
      );
      final access = employeeAccess();

      final saving = controller.saveAsset(access, _asset);
      expect(controller.isSaving, isTrue);
      // A retry or refresh in the same scope while the save is in flight.
      await controller.load(access);
      repository.pendingSave.complete(_asset);

      expect(await saving, isTrue);
      expect(controller.isSaving, isFalse);
      expect(controller.assets.map((a) => a.id), ['asset-1']);
      controller.dispose();
    },
  );
}
