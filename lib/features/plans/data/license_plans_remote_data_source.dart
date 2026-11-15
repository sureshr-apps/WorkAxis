import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';
import 'package:workaxis/features/plans/domain/repositories/license_plans_repository.dart';

/// Remote license plan reads and writes. A thin seam over the data gateway so
/// the repository can be unit-tested with a fake.
abstract interface class LicensePlansRemoteDataSource {
  Future<LicensePlanCatalog> listPlans({String? query, PlanStatus? status});

  /// Inserts the plan; the server generates its id and plan code.
  Future<({String id, String planCode})> createPlan(
    CreateLicensePlanDraft draft,
  );

  /// Returns false when the plan does not exist.
  Future<bool> updatePlan(String id, UpdateLicensePlanDraft draft);

  /// Returns false when the plan does not exist.
  Future<bool> changeStatus(String id, PlanStatus status);

  Future<void> deletePlan(String id);
}
