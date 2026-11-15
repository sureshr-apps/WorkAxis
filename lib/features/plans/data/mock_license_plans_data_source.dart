import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_summary.dart';
import 'package:workaxis/features/plans/domain/repositories/license_plans_repository.dart';

/// Server refusal text for deleting a plan that still has references. Mirrors
/// the message the `DeleteLicensePlan` operation returns.
const String planReferencedMessage =
    'This plan is referenced by existing licenses or history and cannot be '
    'deleted. Deactivate it instead.';

/// In-memory license plan store for mock-first UI work. It enforces the same
/// refusals the server does (unique level, delete while referenced), so screens
/// can exercise those paths without a backend.
class MockLicensePlansDataSource {
  MockLicensePlansDataSource({List<LicensePlan>? seed})
    : _plans = [...(seed ?? _seedPlans)];

  final List<LicensePlan> _plans;
  int _nextCodeNumber = 0x1A2B3C4D5E00;

  /// Seeded catalogue: five plans, one per level, with assigned organizations
  /// on Basic and Plus so the delete refusal is reachable.
  static const List<LicensePlan> _seedPlans = [
    LicensePlan(
      id: 'plan-basic',
      planCode: 'PLN-0000000000A1-BASIC',
      name: 'Basic',
      description: 'Single-location operations for small retail teams.',
      level: 1,
      maxStores: 2,
      maxUsers: 10,
      status: PlanStatus.active,
      assignedOrganizations: 2,
    ),
    LicensePlan(
      id: 'plan-plus',
      planCode: 'PLN-0000000000A2-PLUS',
      name: 'Plus',
      description: 'Growing multi-store businesses with shared rosters.',
      level: 2,
      maxStores: 5,
      maxUsers: 25,
      status: PlanStatus.active,
      assignedOrganizations: 1,
    ),
    LicensePlan(
      id: 'plan-pro',
      planCode: 'PLN-0000000000A3-PRO',
      name: 'Pro',
      description: 'Regional operations with centralised reporting.',
      level: 3,
      maxStores: 10,
      maxUsers: 60,
      status: PlanStatus.active,
    ),
    LicensePlan(
      id: 'plan-business',
      planCode: 'PLN-0000000000A4-BUSINESS',
      name: 'Business',
      description: 'Large chains that need high store and user capacity.',
      level: 4,
      maxStores: 25,
      maxUsers: 150,
      status: PlanStatus.inactive,
    ),
    LicensePlan(
      id: 'plan-enterprise',
      planCode: 'PLN-0000000000A5-ENTERPRISE',
      name: 'Enterprise',
      description: 'National operations at the highest capacity tier.',
      level: 5,
      maxStores: 100,
      maxUsers: 1000,
      status: PlanStatus.active,
    ),
  ];

  /// Plans ordered by level, with the summary computed over the whole
  /// catalogue (the server's summary ignores list filters).
  LicensePlanCatalog list({String? query, PlanStatus? status}) {
    final needle = query?.trim().toLowerCase();
    final plans = _plans.where((plan) {
      if (status != null && plan.status != status) return false;
      if (needle == null || needle.isEmpty) return true;
      return plan.name.toLowerCase().contains(needle) ||
          plan.planCode.toLowerCase().contains(needle);
    }).toList()..sort((a, b) => a.level.compareTo(b.level));
    return LicensePlanCatalog(plans: plans, summary: _summary());
  }

  LicensePlan create(CreateLicensePlanDraft draft) {
    _ensureLevelFree(draft.level, exceptId: null);
    final plan = LicensePlan(
      id: 'plan-${_plans.length + 1}-${draft.level}',
      planCode: _nextPlanCode(draft.name),
      name: draft.name.trim(),
      description: draft.description.trim(),
      level: draft.level,
      maxStores: draft.maxStores,
      maxUsers: draft.maxUsers,
      status: draft.status,
    );
    _plans.add(plan);
    return plan;
  }

  /// Returns false when no plan has [id].
  bool update(String id, UpdateLicensePlanDraft draft) {
    final index = _indexOf(id);
    if (index < 0) return false;
    _ensureLevelFree(draft.level, exceptId: id);
    _plans[index] = _plans[index].copyWith(
      name: draft.name.trim(),
      description: draft.description.trim(),
      level: draft.level,
      maxStores: draft.maxStores,
      maxUsers: draft.maxUsers,
    );
    return true;
  }

  /// Returns false when no plan has [id].
  bool setStatus(String id, PlanStatus status) {
    final index = _indexOf(id);
    if (index < 0) return false;
    _plans[index] = _plans[index].copyWith(status: status);
    return true;
  }

  void delete(String id) {
    final index = _indexOf(id);
    if (index < 0) throw const NotFoundException('License plan not found');
    if (_plans[index].assignedOrganizations > 0) {
      throw DatabaseException(
        'Plan $id is referenced',
        userMessage: planReferencedMessage,
      );
    }
    _plans.removeAt(index);
  }

  int _indexOf(String id) => _plans.indexWhere((plan) => plan.id == id);

  void _ensureLevelFree(int level, {required String? exceptId}) {
    final taken = _plans.any(
      (plan) => plan.level == level && plan.id != exceptId,
    );
    if (taken) {
      throw DatabaseException(
        'Duplicate level $level',
        userMessage: 'A plan with this level already exists.',
      );
    }
  }

  LicensePlanSummary _summary() {
    final active = _plans.where((plan) => plan.isActive).length;
    return LicensePlanSummary(
      totalPlans: _plans.length,
      activePlans: active,
      inactivePlans: _plans.length - active,
      assignedOrganizations: _plans.fold(
        0,
        (sum, plan) => sum + plan.assignedOrganizations,
      ),
    );
  }

  /// `PLN-<12 hex>-<NAME>`, with NAME reduced to up to 10 upper-case letters
  /// as the server does.
  String _nextPlanCode(String name) {
    _nextCodeNumber += 0x1F3;
    final hex = _nextCodeNumber
        .toRadixString(16)
        .toUpperCase()
        .padLeft(12, '0');
    final letters = name.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    final suffix = letters.length > 10 ? letters.substring(0, 10) : letters;
    return 'PLN-$hex-${suffix.isEmpty ? 'PLAN' : suffix}';
  }
}
