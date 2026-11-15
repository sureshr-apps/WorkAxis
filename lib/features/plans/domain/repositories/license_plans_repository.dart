import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_summary.dart';

/// Plans returned by one list request, with the catalogue-wide summary.
class LicensePlanCatalog {
  const LicensePlanCatalog({required this.plans, required this.summary});

  /// Ordered by level ascending.
  final List<LicensePlan> plans;
  final LicensePlanSummary summary;
}

/// Contract for managing the platform license plan catalogue. Platform-only.
abstract interface class LicensePlansRepository {
  /// Plans filtered on the server by [status] and by a case-insensitive
  /// [query] matched against name or plan code.
  Future<LicensePlanCatalog> listPlans({String? query, PlanStatus? status});

  /// Creates a plan and returns it with its server-generated plan code.
  Future<LicensePlan> createPlan(CreateLicensePlanDraft draft);

  /// Saves the editable fields of plan [id]. Status is not changed here.
  Future<void> updatePlan(String id, UpdateLicensePlanDraft draft);

  /// Activates or deactivates plan [id].
  Future<void> changeStatus(String id, PlanStatus status);

  /// Deletes plan [id]. Refused while any license or history row references
  /// it; the refusal message is safe to show.
  Future<void> deletePlan(String id);
}
