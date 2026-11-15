import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// The user-entered fields shared by create and update. Policy validation reads
/// only this view, so both drafts are checked by the same rules.
abstract interface class LicensePlanDraftFields {
  String get name;
  String get description;
  int get level;
  int get maxStores;
  int get maxUsers;
}

/// A new plan to be created. Plans are created [PlanStatus.active] unless the
/// caller asks otherwise.
class CreateLicensePlanDraft implements LicensePlanDraftFields {
  const CreateLicensePlanDraft({
    required this.name,
    this.description = '',
    required this.level,
    required this.maxStores,
    required this.maxUsers,
    this.status = PlanStatus.active,
  });

  @override
  final String name;
  @override
  final String description;
  @override
  final int level;
  @override
  final int maxStores;
  @override
  final int maxUsers;
  final PlanStatus status;
}

/// Edited values for an existing plan. The plan code and status are not
/// editable here; status has its own action.
class UpdateLicensePlanDraft implements LicensePlanDraftFields {
  const UpdateLicensePlanDraft({
    required this.name,
    this.description = '',
    required this.level,
    required this.maxStores,
    required this.maxUsers,
  });

  @override
  final String name;
  @override
  final String description;
  @override
  final int level;
  @override
  final int maxStores;
  @override
  final int maxUsers;
}
