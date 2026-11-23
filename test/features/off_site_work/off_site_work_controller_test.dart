import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';
import 'package:workaxis/features/off_site_work/domain/repositories/off_site_work_repository.dart';
import 'package:workaxis/features/off_site_work/presentation/controllers/off_site_work_controller.dart';

import '../../contracts/acme_scenario.dart';

/// Holds every create until the test completes [pendingCreate].
class _GatedRepository implements OffSiteWorkRepository {
  final pendingCreate = Completer<OffSiteWorkAssignment>();

  @override
  Future<OffSiteWorkAssignment> createAssignment({
    required UserAccessContext access,
    String? activeBranchId,
    required OffSiteWorkAssignmentDraft draft,
  }) => pendingCreate.future;

  @override
  Future<List<OffSiteWorkAssignment>> getAssignments({
    required UserAccessContext access,
    String? activeBranchId,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

OffSiteWorkAssignment _assignment(String id) => OffSiteWorkAssignment(
  id: id,
  organizationId: 'org-acme',
  branchId: 'br-01',
  branchName: 'Branch 1',
  employeeMemberId: 'user-emp-01',
  employeeUid: 'user-emp-01',
  employeeName: 'Sarah Connor',
  assignedByUid: 'user-bm-multi-01',
  assignedByName: 'Marcus Chen',
  title: 'Site visit',
  destination: 'Warehouse',
  status: OffSiteWorkStatus.values.first,
  createdAt: DateTime.utc(2026, 11, 20),
  updatedAt: DateTime.utc(2026, 11, 20),
);

void main() {
  test('a create that lands after a scope reset does not leak into the '
      'new scope', () async {
    final repository = _GatedRepository();
    final controller = OffSiteWorkController(repository: repository);
    final saved = controller.createAssignment(
      access: branchManagerAccess(),
      activeBranchId: 'br-01',
      draft: const OffSiteWorkAssignmentDraft(
        branchId: 'br-01',
        employeeMemberId: 'user-emp-01',
        title: 'Site visit',
        destination: 'Warehouse',
        destinationLatitude: 12.97,
        destinationLongitude: 77.59,
      ),
    );

    // Branch switch or sign-out while the request is in flight.
    controller.reset();
    repository.pendingCreate.complete(_assignment('late'));

    expect(await saved, isFalse);
    expect(controller.items, isEmpty);
    controller.dispose();
  });
}
