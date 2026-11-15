import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/plans/data/mock_license_plans_data_source.dart';
import 'package:workaxis/features/plans/domain/license_plan_policy.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';
import 'package:workaxis/features/plans/domain/repositories/license_plans_repository.dart';

/// Mock [LicensePlansRepository] for mock-first UI work. Applies the same
/// validation as the production repository before touching the store.
class MockLicensePlansRepository implements LicensePlansRepository {
  MockLicensePlansRepository({MockLicensePlansDataSource? dataSource})
    : _dataSource = dataSource ?? MockLicensePlansDataSource();

  final MockLicensePlansDataSource _dataSource;

  MockLicensePlansDataSource get dataSource => _dataSource;

  @override
  Future<LicensePlanCatalog> listPlans({
    String? query,
    PlanStatus? status,
  }) async => _dataSource.list(query: query, status: status);

  @override
  Future<LicensePlan> createPlan(CreateLicensePlanDraft draft) async {
    LicensePlanPolicy.ensureValid(draft);
    return _dataSource.create(draft);
  }

  @override
  Future<void> updatePlan(String id, UpdateLicensePlanDraft draft) async {
    LicensePlanPolicy.ensureValid(draft);
    final found = _dataSource.update(id, draft);
    if (!found) {
      throw const NotFoundException('License plan not found');
    }
  }

  @override
  Future<void> changeStatus(String id, PlanStatus status) async {
    final found = _dataSource.setStatus(id, status);
    if (!found) {
      throw const NotFoundException('License plan not found');
    }
  }

  @override
  Future<void> deletePlan(String id) async => _dataSource.delete(id);
}
