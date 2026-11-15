import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/plans/data/license_plans_remote_data_source.dart';
import 'package:workaxis/features/plans/domain/license_plan_policy.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';
import 'package:workaxis/features/plans/domain/repositories/license_plans_repository.dart';

/// Production [LicensePlansRepository]: validates each draft with
/// [LicensePlanPolicy] before the remote call and maps the results to the
/// domain model.
class SqlConnectLicensePlansRepository implements LicensePlansRepository {
  SqlConnectLicensePlansRepository({required this._dataSource});

  final LicensePlansRemoteDataSource _dataSource;

  @override
  Future<LicensePlanCatalog> listPlans({String? query, PlanStatus? status}) =>
      _dataSource.listPlans(query: query, status: status);

  @override
  Future<LicensePlan> createPlan(CreateLicensePlanDraft draft) async {
    LicensePlanPolicy.ensureValid(draft);
    final created = await _dataSource.createPlan(draft);
    return LicensePlan(
      id: created.id,
      planCode: created.planCode,
      name: draft.name.trim(),
      description: draft.description.trim(),
      level: draft.level,
      maxStores: draft.maxStores,
      maxUsers: draft.maxUsers,
      status: draft.status,
    );
  }

  @override
  Future<void> updatePlan(String id, UpdateLicensePlanDraft draft) async {
    LicensePlanPolicy.ensureValid(draft);
    final found = await _dataSource.updatePlan(id, draft);
    if (!found) throw const NotFoundException('License plan not found');
  }

  @override
  Future<void> changeStatus(String id, PlanStatus status) async {
    final found = await _dataSource.changeStatus(id, status);
    if (!found) throw const NotFoundException('License plan not found');
  }

  @override
  Future<void> deletePlan(String id) => _dataSource.deletePlan(id);
}
