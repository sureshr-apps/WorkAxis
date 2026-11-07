import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/branch_dashboard/domain/repositories/branch_dashboard_repository.dart';
import 'package:workaxis/features/branch_dashboard/presentation/controllers/branch_dashboard_controller.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';

import '../../helpers/access_fixtures.dart';

class _GatedBranchRepository implements BranchDashboardRepository {
  final Map<String, Completer<void>> gates = {};
  bool failNext = false;

  @override
  Future<BranchDashboardSummary> getBranchDashboardSummary({
    required UserAccessContext access,
    required String branchId,
  }) async {
    await gates[branchId]?.future;
    if (failNext) throw StateError('boom: db password=hunter2');
    return BranchDashboardSummary(
      branchId: branchId,
      branchName: 'Branch $branchId',
      branchCode: branchId.toUpperCase(),
      attendance: const AttendanceSummary(
        present: 1,
        late: 0,
        absent: 0,
        onLeave: 0,
        totalScheduled: 1,
      ),
      pendingReturns: 0,
      totalEmployees: 1,
      attentionItems: const [],
    );
  }
}

void main() {
  final access = branchManagerAccess();
  late _GatedBranchRepository repository;
  late BranchDashboardController controller;

  setUp(() {
    repository = _GatedBranchRepository();
    controller = BranchDashboardController(repository: repository);
  });

  tearDown(() => controller.dispose());

  test('a late response for branch A never shows under branch B', () async {
    final gateA = Completer<void>();
    repository.gates['a'] = gateA;

    final loadA = controller.loadDashboard(access: access, branchId: 'a');
    await controller.loadDashboard(access: access, branchId: 'b');

    expect(controller.loadedBranchId, 'b');
    expect(controller.summary?.branchId, 'b');

    gateA.complete();
    await loadA;

    expect(controller.loadedBranchId, 'b');
    expect(controller.summary?.branchId, 'b');
    expect(controller.status, BranchDashboardStatus.loaded);
  });

  test('reset() discards an in-flight load', () async {
    final gate = Completer<void>();
    repository.gates['a'] = gate;

    final load = controller.loadDashboard(access: access, branchId: 'a');
    controller.reset();
    gate.complete();
    await load;

    expect(controller.status, BranchDashboardStatus.initial);
    expect(controller.summary, isNull);
    expect(controller.loadedBranchId, isNull);
  });

  test('errors show a safe message, not the raw exception', () async {
    repository.failNext = true;

    await controller.loadDashboard(access: access, branchId: 'a');

    expect(controller.hasError, isTrue);
    expect(controller.errorMessage, isNot(contains('hunter2')));
    expect(controller.errorMessage, isNot(contains('StateError')));
  });
}
