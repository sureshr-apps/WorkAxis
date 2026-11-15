import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/plans/data/mock_license_plans_data_source.dart';
import 'package:workaxis/features/plans/data/mock_license_plans_repository.dart';
import 'package:workaxis/features/plans/domain/license_plan_policy.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';
import 'package:workaxis/features/plans/domain/repositories/license_plans_repository.dart';
import 'package:workaxis/features/plans/presentation/controllers/license_plans_controller.dart';

/// Lets the debounced search timer and the mock futures run to completion.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<String> _names(LicensePlansController c) =>
    c.plans.map((p) => p.name).toList();

void main() {
  late LicensePlansController controller;

  Future<LicensePlansController> loaded() async {
    final c = LicensePlansController(
      repository: MockLicensePlansRepository(),
      searchDebounce: Duration.zero,
    );
    addTearDown(c.dispose);
    await c.loadPlans();
    return c;
  }

  setUp(() async {
    controller = await loaded();
  });

  test('loads plans in level order with the catalogue summary', () {
    expect(_names(controller), [
      'Basic',
      'Plus',
      'Pro',
      'Business',
      'Enterprise',
    ]);
    expect(controller.summary.totalPlans, 5);
    expect(controller.summary.activePlans, 4);
    expect(controller.summary.inactivePlans, 1);
    expect(controller.summary.assignedOrganizations, 3);
    expect(controller.isListLoading, isFalse);
    expect(controller.listErrorMessage, isNull);
  });

  test('offers every loaded level, ascending', () {
    expect(controller.availableLevels, [1, 2, 3, 4, 5]);
  });

  test('status filter reloads from the server', () async {
    controller.setStatusFilter(PlanStatus.inactive);
    await _settle();

    expect(_names(controller), ['Business']);
    expect(controller.statusFilter, PlanStatus.inactive);
    // The summary describes the catalogue, not the filtered view.
    expect(controller.summary.totalPlans, 5);
  });

  test('search is debounced and matches name or plan code', () async {
    controller.setSearchQuery('PRO');
    await _settle();

    expect(_names(controller), ['Pro']);
    expect(controller.searchQuery, 'PRO');
    expect(controller.hasActiveFilters, isTrue);
  });

  test('level filter narrows the loaded rows without reloading', () async {
    controller.setLevelFilter(3);

    expect(_names(controller), ['Pro']);
    expect(controller.highestVisiblePlan?.name, 'Pro');
    expect(controller.levelFilter, 3);
  });

  test('highest visible plan is the top level of the visible rows', () {
    expect(controller.highestVisiblePlan?.name, 'Enterprise');

    controller.setLevelFilter(2);
    expect(controller.highestVisiblePlan?.name, 'Plus');
  });

  test('visible rows stay sorted by level after a reload', () async {
    controller.setStatusFilter(null);
    await _settle();

    final levels = controller.plans.map((p) => p.level).toList();
    expect(levels, [...levels]..sort());
  });

  test('resetFilters clears search, status and level', () async {
    controller.setSearchQuery('pro');
    controller.setLevelFilter(3);
    controller.setStatusFilter(PlanStatus.active);
    await _settle();

    controller.resetFilters();
    await _settle();

    expect(controller.hasActiveFilters, isFalse);
    expect(controller.searchQuery, isEmpty);
    expect(_names(controller), hasLength(5));
  });

  test('deactivating a plan updates the row and the summary', () async {
    final ok = await controller.changeStatus('plan-pro', PlanStatus.inactive);

    expect(ok, isTrue);
    final pro = controller.plans.firstWhere((p) => p.id == 'plan-pro');
    expect(pro.status, PlanStatus.inactive);
    expect(controller.summary.activePlans, 3);
    expect(controller.summary.inactivePlans, 2);
    expect(controller.actionErrorMessage, isNull);
  });

  test(
    'deleting a referenced plan is refused with the server message',
    () async {
      final ok = await controller.deletePlan('plan-basic');

      expect(ok, isFalse);
      expect(controller.actionErrorMessage, planReferencedMessage);
      expect(controller.isActionLoading, isFalse);
      expect(_names(controller), contains('Basic'));
    },
  );

  test('deleting an unreferenced plan removes it', () async {
    final ok = await controller.deletePlan('plan-enterprise');

    expect(ok, isTrue);
    expect(_names(controller), isNot(contains('Enterprise')));
    expect(controller.summary.totalPlans, 4);
  });

  test('clearActionError drops the message', () async {
    await controller.deletePlan('plan-basic');
    controller.clearActionError();

    expect(controller.actionErrorMessage, isNull);
  });

  test(
    'an invalid draft is reported as a field message, not a crash',
    () async {
      final created = await controller.createPlan(
        const CreateLicensePlanDraft(
          name: '  ',
          level: 9,
          maxStores: 1,
          maxUsers: 1,
        ),
      );

      expect(created, isNull);
      expect(
        controller.actionErrorMessage,
        LicensePlanPolicy.nameRequiredMessage,
      );
      expect(controller.plans, hasLength(5));
    },
  );

  test('create adds the plan and returns it', () async {
    final created = await controller.createPlan(
      const CreateLicensePlanDraft(
        name: 'Starter',
        level: 9,
        maxStores: 1,
        maxUsers: 5,
      ),
    );

    expect(created?.name, 'Starter');
    expect(controller.availableLevels.last, 9);
    expect(controller.plans.map((p) => p.name), contains('Starter'));
  });

  test('a server level conflict is shown as the action error', () async {
    final ok = await controller.updatePlan(
      'plan-pro',
      const UpdateLicensePlanDraft(
        name: 'Pro',
        level: 1,
        maxStores: 1,
        maxUsers: 1,
      ),
    );

    expect(ok, isFalse);
    expect(
      controller.actionErrorMessage,
      'A plan with this level already exists.',
    );
  });

  test('reset discards loaded data and filters', () async {
    controller.setSearchQuery('pro');
    await _settle();

    controller.reset();

    expect(controller.plans, isEmpty);
    expect(controller.summary.totalPlans, 0);
    expect(controller.searchQuery, isEmpty);
    expect(controller.statusFilter, isNull);
    expect(controller.levelFilter, isNull);
  });

  test('a failing load keeps a user-safe message', () async {
    final failing = LicensePlansController(
      repository: _FailingRepository(),
      searchDebounce: Duration.zero,
    );
    addTearDown(failing.dispose);

    await failing.loadPlans();

    expect(
      failing.listErrorMessage,
      'Could not load license plans. Please try again.',
    );
    expect(failing.plans, isEmpty);
  });

  test('the controller can share one data source', () async {
    final dataSource = MockLicensePlansDataSource();
    final shared = LicensePlansController(
      repository: MockLicensePlansRepository(dataSource: dataSource),
      searchDebounce: Duration.zero,
    );
    addTearDown(shared.dispose);
    await shared.loadPlans();

    expect(shared.summary.totalPlans, 5);
  });
}

class _FailingRepository extends MockLicensePlansRepository {
  @override
  Future<LicensePlanCatalog> listPlans({
    String? query,
    PlanStatus? status,
  }) async {
    throw StateError('network down');
  }
}
