import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/plans/data/sql_connect_license_plans_remote_data_source.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';

import '../../../helpers/fake_data_gateway.dart';

const String _refusedMessage =
    'This plan is referenced by existing licenses or history and cannot be '
    'deleted. Deactivate it instead.';

Map<String, dynamic> _row({
  String id = 'plan-pro',
  String name = 'Pro',
  Object? description = 'Regional',
  int level = 3,
  String status = 'active',
  int assigned = 1,
}) => {
  'id': id,
  'planCode': 'PLN-0000000000A3-PRO',
  'name': name,
  'description': description,
  'level': level,
  'maxStores': 10,
  'maxUsers': 60,
  'status': status,
  'assignedOrganizations': assigned,
};

Map<String, dynamic> _summary() => {
  'totalPlans': 5,
  'activePlans': 4,
  'inactivePlans': 1,
  'assignedOrganizations': 3,
};

/// Fails every call with [error], as a refused callable would.
class _RefusingGateway extends FakeDataGateway {
  _RefusingGateway(this.error);

  final AppException error;

  @override
  Future<Map<String, dynamic>> call(
    String op, [
    Map<String, dynamic> vars = const {},
  ]) async {
    throw error;
  }
}

void main() {
  late FakeDataGateway gateway;
  late SqlConnectLicensePlansRemoteDataSource source;

  setUp(() {
    gateway = FakeDataGateway();
    source = SqlConnectLicensePlansRemoteDataSource(gateway: gateway);
  });

  group('listPlans', () {
    test('omits unset filters and reads rows and summary', () async {
      gateway.respond('ListLicensePlans', {
        'licensePlans': [_row(description: null)],
        'summary': _summary(),
      });

      final catalog = await source.listPlans();

      expect(gateway.singleVarsOf('ListLicensePlans'), <String, dynamic>{});
      final plan = catalog.plans.single;
      expect(plan.id, 'plan-pro');
      expect(plan.planCode, 'PLN-0000000000A3-PRO');
      expect(plan.description, '');
      expect(plan.level, 3);
      expect(plan.maxStores, 10);
      expect(plan.maxUsers, 60);
      expect(plan.status, PlanStatus.active);
      expect(plan.assignedOrganizations, 1);
      expect(catalog.summary.totalPlans, 5);
      expect(catalog.summary.activePlans, 4);
      expect(catalog.summary.inactivePlans, 1);
      expect(catalog.summary.assignedOrganizations, 3);
    });

    test('sends the trimmed query and the status filter', () async {
      gateway.respond('ListLicensePlans', {
        'licensePlans': <dynamic>[],
        'summary': _summary(),
      });

      await source.listPlans(query: '  pro ', status: PlanStatus.inactive);

      expect(gateway.singleVarsOf('ListLicensePlans'), {
        'query': 'pro',
        'status': 'inactive',
      });
    });

    test('does not send a blank query', () async {
      gateway.respond('ListLicensePlans', {
        'licensePlans': <dynamic>[],
        'summary': _summary(),
      });

      await source.listPlans(query: '   ', status: PlanStatus.active);

      expect(gateway.singleVarsOf('ListLicensePlans'), {'status': 'active'});
    });

    test('maps an unknown status to inactive', () async {
      gateway.respond('ListLicensePlans', {
        'licensePlans': [_row(status: 'ARCHIVED')],
        'summary': _summary(),
      });

      final plan = (await source.listPlans()).plans.single;

      expect(plan.status, PlanStatus.inactive);
    });
  });

  test(
    'createPlan sends trimmed fields and the status, and returns id and code',
    () async {
      gateway.respond('CreateLicensePlan', {
        'licensePlan_insert': {
          'id': 'plan-new',
          'planCode': 'PLN-AAAA00001111-STARTER',
        },
      });

      final created = await source.createPlan(
        const CreateLicensePlanDraft(
          name: ' Starter ',
          description: ' Small teams ',
          level: 1,
          maxStores: 2,
          maxUsers: 10,
        ),
      );

      expect(gateway.singleVarsOf('CreateLicensePlan'), {
        'name': 'Starter',
        'description': 'Small teams',
        'level': 1,
        'maxStores': 2,
        'maxUsers': 10,
        'status': 'active',
      });
      expect(created.id, 'plan-new');
      expect(created.planCode, 'PLN-AAAA00001111-STARTER');
    },
  );

  test('createPlan sends an empty description rather than null', () async {
    gateway.respond('CreateLicensePlan', {
      'licensePlan_insert': {
        'id': 'plan-new',
        'planCode': 'PLN-AAAA00001111-X',
      },
    });

    await source.createPlan(
      const CreateLicensePlanDraft(
        name: 'X',
        level: 4,
        maxStores: 1,
        maxUsers: 1,
        status: PlanStatus.inactive,
      ),
    );

    final vars = gateway.singleVarsOf('CreateLicensePlan');
    expect(vars['description'], '');
    expect(vars['status'], 'inactive');
  });

  group('updatePlan', () {
    test('sends the id and editable fields and reports success', () async {
      gateway.respond('UpdateLicensePlan', {
        'licensePlan_update': {'id': 'plan-pro'},
      });

      final found = await source.updatePlan(
        'plan-pro',
        const UpdateLicensePlanDraft(
          name: 'Pro',
          level: 3,
          maxStores: 12,
          maxUsers: 70,
        ),
      );

      expect(found, isTrue);
      expect(gateway.singleVarsOf('UpdateLicensePlan'), {
        'id': 'plan-pro',
        'name': 'Pro',
        'description': '',
        'level': 3,
        'maxStores': 12,
        'maxUsers': 70,
      });
    });

    test('reports a missing plan when the server returns null', () async {
      gateway.respond('UpdateLicensePlan', {'licensePlan_update': null});

      final found = await source.updatePlan(
        'gone',
        const UpdateLicensePlanDraft(
          name: 'Pro',
          level: 3,
          maxStores: 1,
          maxUsers: 1,
        ),
      );

      expect(found, isFalse);
    });
  });

  group('changeStatus', () {
    test('sends the id and the status name', () async {
      gateway.respond('ChangeLicensePlanStatus', {
        'licensePlan_update': {'id': 'plan-pro', 'status': 'inactive'},
      });

      final found = await source.changeStatus('plan-pro', PlanStatus.inactive);

      expect(found, isTrue);
      expect(gateway.singleVarsOf('ChangeLicensePlanStatus'), {
        'id': 'plan-pro',
        'status': 'inactive',
      });
    });

    test('reports a missing plan when the server returns null', () async {
      gateway.respond('ChangeLicensePlanStatus', {'licensePlan_update': null});

      expect(await source.changeStatus('gone', PlanStatus.active), isFalse);
    });
  });

  test('deletePlan sends the id to DeleteLicensePlan', () async {
    gateway.respond('DeleteLicensePlan', {
      'licensePlan_delete': {'id': 'plan-pro'},
    });

    await source.deletePlan('plan-pro');

    expect(gateway.singleVarsOf('DeleteLicensePlan'), {'id': 'plan-pro'});
  });

  test('a refused delete surfaces the server message unchanged', () async {
    final refusing = SqlConnectLicensePlansRemoteDataSource(
      gateway: _RefusingGateway(
        const DatabaseException(
          'Callable failed-precondition',
          userMessage: _refusedMessage,
        ),
      ),
    );

    await expectLater(
      refusing.deletePlan('plan-basic'),
      throwsA(
        isA<DatabaseException>().having(
          (e) => e.userMessage,
          'userMessage',
          _refusedMessage,
        ),
      ),
    );
  });
}
