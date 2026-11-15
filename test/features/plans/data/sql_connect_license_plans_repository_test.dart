import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/plans/data/license_plans_remote_data_source.dart';
import 'package:workaxis/features/plans/data/sql_connect_license_plans_repository.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_summary.dart';
import 'package:workaxis/features/plans/domain/repositories/license_plans_repository.dart';

/// Counts writes so tests can prove validation stops them.
class _RecordingDataSource implements LicensePlansRemoteDataSource {
  int writes = 0;
  bool found = true;

  @override
  Future<LicensePlanCatalog> listPlans({
    String? query,
    PlanStatus? status,
  }) async =>
      const LicensePlanCatalog(plans: [], summary: LicensePlanSummary.empty);

  @override
  Future<({String id, String planCode})> createPlan(
    CreateLicensePlanDraft draft,
  ) async {
    writes++;
    return (id: 'plan-new', planCode: 'PLN-0000000000AB-STARTER');
  }

  @override
  Future<bool> updatePlan(String id, UpdateLicensePlanDraft draft) async {
    writes++;
    return found;
  }

  @override
  Future<bool> changeStatus(String id, PlanStatus status) async {
    writes++;
    return found;
  }

  @override
  Future<void> deletePlan(String id) async {
    writes++;
  }
}

void main() {
  late _RecordingDataSource dataSource;
  late LicensePlansRepository repository;

  setUp(() {
    dataSource = _RecordingDataSource();
    repository = SqlConnectLicensePlansRepository(dataSource: dataSource);
  });

  test('an invalid draft is rejected before any remote call', () async {
    await expectLater(
      repository.createPlan(
        const CreateLicensePlanDraft(
          name: ' ',
          level: 1,
          maxStores: 1,
          maxUsers: 1,
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      repository.updatePlan(
        'plan-pro',
        const UpdateLicensePlanDraft(
          name: 'Pro',
          level: 3,
          maxStores: 0,
          maxUsers: 1,
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(dataSource.writes, 0);
  });

  test('createPlan returns the saved plan with the server plan code', () async {
    final plan = await repository.createPlan(
      const CreateLicensePlanDraft(
        name: ' Starter ',
        description: 'Small',
        level: 1,
        maxStores: 2,
        maxUsers: 10,
      ),
    );

    expect(plan.id, 'plan-new');
    expect(plan.planCode, 'PLN-0000000000AB-STARTER');
    expect(plan.name, 'Starter');
    expect(plan.status, PlanStatus.active);
    expect(plan.assignedOrganizations, 0);
  });

  test('a plan that no longer exists raises NotFoundException', () async {
    dataSource.found = false;

    await expectLater(
      repository.updatePlan(
        'gone',
        const UpdateLicensePlanDraft(
          name: 'Pro',
          level: 3,
          maxStores: 1,
          maxUsers: 1,
        ),
      ),
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      repository.changeStatus('gone', PlanStatus.inactive),
      throwsA(isA<NotFoundException>()),
    );
  });
}
