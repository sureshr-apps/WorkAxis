import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/plans/data/mock_license_plans_data_source.dart';
import 'package:workaxis/features/plans/data/mock_license_plans_repository.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';

final RegExp _planCodePattern = RegExp(r'^PLN-[0-9A-F]{12}-[A-Z]{1,10}$');

void main() {
  late MockLicensePlansRepository repository;

  setUp(() {
    repository = MockLicensePlansRepository();
  });

  group('seed catalogue', () {
    test('has five plans, one per level, in level order', () async {
      final catalog = await repository.listPlans();

      expect(catalog.plans.map((p) => p.name), [
        'Basic',
        'Plus',
        'Pro',
        'Business',
        'Enterprise',
      ]);
      expect(catalog.plans.map((p) => p.level), [1, 2, 3, 4, 5]);
    });

    test('every seeded plan code has the server format', () async {
      final catalog = await repository.listPlans();

      for (final plan in catalog.plans) {
        expect(
          _planCodePattern.hasMatch(plan.planCode),
          isTrue,
          reason: plan.planCode,
        );
      }
    });

    test('summary counts the whole catalogue', () async {
      final summary = (await repository.listPlans()).summary;

      expect(summary.totalPlans, 5);
      expect(summary.activePlans, 4);
      expect(summary.inactivePlans, 1);
      expect(summary.assignedOrganizations, 3);
    });

    test('summary ignores list filters', () async {
      final filtered = await repository.listPlans(
        status: PlanStatus.inactive,
        query: 'basic',
      );

      expect(filtered.plans, isEmpty);
      expect(filtered.summary.totalPlans, 5);
    });
  });

  test('list matches the name or the plan code, case-insensitively', () async {
    expect(
      (await repository.listPlans(query: 'ENTER')).plans.map((p) => p.name),
      ['Enterprise'],
    );
    expect((await repository.listPlans(query: 'no-such-plan')).plans, isEmpty);
    expect(
      (await repository.listPlans(query: '0000000000a4')).plans
          .map((p) => p.name),
      ['Business'],
    );
  });

  test('create generates a code in the server format and enforces level uniqueness', () async {
    final created = await repository.createPlan(
      const CreateLicensePlanDraft(
        name: 'Ultra Mega Enterprise Edition Plus',
        level: 6,
        maxStores: 500,
        maxUsers: 5000,
      ),
    );

    expect(
      _planCodePattern.hasMatch(created.planCode),
      isTrue,
      reason: created.planCode,
    );
    expect(created.planCode, endsWith('-ULTRAMEGAE'));
    expect(created.status, PlanStatus.active);

    await expectLater(
      repository.createPlan(
        const CreateLicensePlanDraft(
          name: 'Duplicate',
          level: 3,
          maxStores: 1,
          maxUsers: 1,
        ),
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.userMessage,
          'userMessage',
          'A plan with this level already exists.',
        ),
      ),
    );
  });

  test('create applies the policy before writing', () async {
    await expectLater(
      repository.createPlan(
        const CreateLicensePlanDraft(
          name: '',
          level: 7,
          maxStores: 1,
          maxUsers: 1,
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
    expect((await repository.listPlans()).plans, hasLength(5));
  });

  test('update keeps the level unique and saves the new values', () async {
    await repository.updatePlan(
      'plan-pro',
      const UpdateLicensePlanDraft(
        name: 'Pro Plus',
        description: '  Updated  ',
        level: 3,
        maxStores: 12,
        maxUsers: 70,
      ),
    );
    final pro = (await repository.listPlans()).plans.firstWhere(
      (p) => p.id == 'plan-pro',
    );
    expect(pro.name, 'Pro Plus');
    expect(pro.description, 'Updated');
    expect(pro.maxStores, 12);

    await expectLater(
      repository.updatePlan(
        'plan-pro',
        const UpdateLicensePlanDraft(
          name: 'Pro',
          level: 1,
          maxStores: 1,
          maxUsers: 1,
        ),
      ),
      throwsA(isA<AppException>()),
    );
  });

  test(
    'updating or changing a missing plan raises NotFoundException',
    () async {
      await expectLater(
        repository.updatePlan(
          'missing',
          const UpdateLicensePlanDraft(
            name: 'X',
            level: 9,
            maxStores: 1,
            maxUsers: 1,
          ),
        ),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        repository.changeStatus('missing', PlanStatus.active),
        throwsA(isA<NotFoundException>()),
      );
    },
  );

  test('change status toggles the plan and the summary', () async {
    await repository.changeStatus('plan-pro', PlanStatus.inactive);

    final catalog = await repository.listPlans();
    final pro = catalog.plans.firstWhere((p) => p.id == 'plan-pro');
    expect(pro.status, PlanStatus.inactive);
    expect(catalog.summary.activePlans, 3);
    expect(catalog.summary.inactivePlans, 2);
  });

  test('delete is refused with the server message while organizations are assigned', () async {
    await expectLater(
      repository.deletePlan('plan-basic'),
      throwsA(
        isA<AppException>().having(
          (e) => e.userMessage,
          'userMessage',
          planReferencedMessage,
        ),
      ),
    );
    expect((await repository.listPlans()).plans, hasLength(5));
  });

  test('delete removes an unreferenced plan', () async {
    await repository.deletePlan('plan-enterprise');

    final names = (await repository.listPlans()).plans.map((p) => p.name);
    expect(names, isNot(contains('Enterprise')));
    expect(names, hasLength(4));
  });

  test('repositories built on one data source share its state', () async {
    final dataSource = MockLicensePlansDataSource();
    final first = MockLicensePlansRepository(dataSource: dataSource);
    final second = MockLicensePlansRepository(dataSource: dataSource);

    await first.changeStatus('plan-plus', PlanStatus.inactive);

    expect((await second.listPlans()).summary.inactivePlans, 2);
  });
}
