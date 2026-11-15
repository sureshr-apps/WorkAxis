import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/features/plans/data/license_plans_remote_data_source.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_summary.dart';
import 'package:workaxis/features/plans/domain/repositories/license_plans_repository.dart';

/// [LicensePlansRemoteDataSource] backed by the `dataOp` callable.
///
/// Operations: `ListLicensePlans`, `CreateLicensePlan`, `UpdateLicensePlan`,
/// `ChangeLicensePlanStatus`, `DeleteLicensePlan`. Refusals (for example a
/// plan still referenced by a license) reach the caller as an [AppException]
/// whose user message is the server's message.
class SqlConnectLicensePlansRemoteDataSource
    implements LicensePlansRemoteDataSource {
  SqlConnectLicensePlansRemoteDataSource({required this._gateway});

  final DataGateway _gateway;

  @override
  Future<LicensePlanCatalog> listPlans({
    String? query,
    PlanStatus? status,
  }) async {
    final trimmedQuery = query?.trim();
    final data = await _gateway.call('ListLicensePlans', {
      // Unset optional variables are omitted, never sent as null.
      if (trimmedQuery != null && trimmedQuery.isNotEmpty)
        'query': trimmedQuery,
      'status': ?status?.name,
    });
    final summary = data.object('summary');
    return LicensePlanCatalog(
      plans: [for (final row in data.objects('licensePlans')) _plan(row)],
      summary: LicensePlanSummary(
        totalPlans: summary.integer('totalPlans'),
        activePlans: summary.integer('activePlans'),
        inactivePlans: summary.integer('inactivePlans'),
        assignedOrganizations: summary.integer('assignedOrganizations'),
      ),
    );
  }

  @override
  Future<({String id, String planCode})> createPlan(
    CreateLicensePlanDraft draft,
  ) async {
    final data = await _gateway.call('CreateLicensePlan', {
      'name': draft.name.trim(),
      'description': draft.description.trim(),
      'level': draft.level,
      'maxStores': draft.maxStores,
      'maxUsers': draft.maxUsers,
      'status': draft.status.name,
    });
    final inserted = data.object('licensePlan_insert');
    return (id: inserted.string('id'), planCode: inserted.string('planCode'));
  }

  @override
  Future<bool> updatePlan(String id, UpdateLicensePlanDraft draft) async {
    final data = await _gateway.call('UpdateLicensePlan', {
      'id': id,
      'name': draft.name.trim(),
      // Sent even when empty so a cleared description is saved.
      'description': draft.description.trim(),
      'level': draft.level,
      'maxStores': draft.maxStores,
      'maxUsers': draft.maxUsers,
    });
    return data.optObject('licensePlan_update') != null;
  }

  @override
  Future<bool> changeStatus(String id, PlanStatus status) async {
    final data = await _gateway.call('ChangeLicensePlanStatus', {
      'id': id,
      'status': status.name,
    });
    return data.optObject('licensePlan_update') != null;
  }

  @override
  Future<void> deletePlan(String id) async {
    await _gateway.call('DeleteLicensePlan', {'id': id});
  }

  LicensePlan _plan(Map<String, dynamic> row) => LicensePlan(
    id: row.string('id'),
    planCode: row.string('planCode'),
    name: row.string('name'),
    description: row.optString('description') ?? '',
    level: row.integer('level'),
    maxStores: row.integer('maxStores'),
    maxUsers: row.integer('maxUsers'),
    status: PlanStatus.fromString(row.optString('status')),
    assignedOrganizations: row.integer('assignedOrganizations'),
  );
}
