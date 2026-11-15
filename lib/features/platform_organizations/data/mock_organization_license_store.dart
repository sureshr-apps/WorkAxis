import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_license_rules.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Development fake for license state, used only by the mock repositories.
///
/// It follows the server rules (validation, history rows, the contiguous
/// renewal rule, status derived from business dates) so every UI state can be
/// reached without a backend. Production never computes status on the client.
class MockOrganizationLicenseStore {
  MockOrganizationLicenseStore({this.now = systemNow}) {
    _seed();
  }

  /// Source of the current instant; inject a fixed clock in tests.
  final Now now;
  final List<LicensePlan> _plans = _catalogue;
  final Map<String, _LicenseRecord> _records = {};
  int _nextNumber = 1;

  /// Plans that may be assigned or selected, lowest level first.
  List<LicensePlan> activePlans() =>
      OrganizationLicenseRules.assignablePlans(_plans);

  OrganizationLicense? getLicense(String organizationId) {
    final record = _records[organizationId];
    return record == null ? null : _toLicense(record);
  }

  List<LicenseHistoryEvent> getHistory(String organizationId) =>
      OrganizationLicenseRules.newestFirst(
        _records[organizationId]?.history ?? const [],
      );

  void assign(String organizationId, AssignLicenseRequest request) {
    if (_records.containsKey(organizationId)) {
      throw ValidationException('This organization already has a license.');
    }
    _requireActivePlan(request.planId);
    _requireValidTerm(request.startDate, request.expiryDate);
    _requirePrices(request.negotiatedPrice, request.maintenancePrice);
    final record = _LicenseRecord(
      id: 'lic-${_nextNumber++}',
      organizationId: organizationId,
      planId: request.planId,
      startDate: CalendarDate.of(request.startDate),
      expiryDate: CalendarDate.of(request.expiryDate),
      negotiatedPrice: request.negotiatedPrice,
      maintenancePrice: request.maintenancePrice,
    );
    _records[organizationId] = record;
    _addEvent(record, LicenseEventType.assigned);
  }

  void changePlan(String organizationId, ChangeLicensePlanRequest request) {
    final record = _requireLicense(organizationId);
    final current = _planById(record.planId);
    final target = _planById(request.targetPlanId);
    if (target.status != PlanStatus.active || target.level <= current.level) {
      throw ValidationException(
        'Only a higher-level active plan can be selected.',
      );
    }
    _requirePrices(request.negotiatedPrice, request.maintenancePrice);
    record
      ..planId = target.id
      ..negotiatedPrice = request.negotiatedPrice
      ..maintenancePrice = request.maintenancePrice;
    _addEvent(record, LicenseEventType.planChanged);
  }

  void modifyCommercialTerms(
    String organizationId,
    ModifyCommercialTermsRequest request,
  ) {
    final record = _requireLicense(organizationId);
    _requirePrices(request.negotiatedPrice, request.maintenancePrice);
    final unchanged =
        record.negotiatedPrice == request.negotiatedPrice &&
        record.maintenancePrice == request.maintenancePrice;
    if (unchanged) return;
    record
      ..negotiatedPrice = request.negotiatedPrice
      ..maintenancePrice = request.maintenancePrice;
    _addEvent(record, LicenseEventType.commercialTermsModified);
  }

  void renew(String organizationId, RenewLicenseRequest request) {
    final record = _requireLicense(organizationId);
    final current = _planById(record.planId);
    final plan = _planById(request.planId);
    final termError = OrganizationLicenseRules.renewalTermError(
      currentExpiry: record.expiryDate,
      newStart: request.newStartDate,
      newExpiry: request.newExpiryDate,
    );
    if (termError != null) throw ValidationException(termError);
    if (plan.status != PlanStatus.active || plan.level < current.level) {
      throw ValidationException(
        'Renewal requires the same or a higher-level active plan.',
      );
    }
    _requirePrices(request.negotiatedPrice, request.maintenancePrice);

    // Back-to-back renewal of a running term keeps the current start date.
    final continuesTerm =
        _isUsableToday(record) &&
        CalendarDate.of(request.newStartDate) ==
            CalendarDate.addDays(record.expiryDate, 1);
    record
      ..planId = plan.id
      ..startDate = continuesTerm
          ? record.startDate
          : CalendarDate.of(request.newStartDate)
      ..expiryDate = CalendarDate.of(request.newExpiryDate)
      ..negotiatedPrice = request.negotiatedPrice
      ..maintenancePrice = request.maintenancePrice;
    _addEvent(record, LicenseEventType.renewed);
  }

  /// Drops the license of a deleted organization.
  void remove(String organizationId) => _records.remove(organizationId);

  // ---- Internals ---------------------------------------------------------

  void _seed() {
    final today = _today();
    final record = _LicenseRecord(
      id: 'lic-${_nextNumber++}',
      organizationId: 'org-acme',
      planId: 'plan-plus',
      startDate: CalendarDate.addDays(today, -60),
      expiryDate: CalendarDate.addDays(today, 305),
      negotiatedPrice: 120000,
      maintenancePrice: 18000,
    );
    _records[record.organizationId] = record;
    record.history.add(
      _event(
        record,
        LicenseEventType.assigned,
        DateTime.utc(
          record.startDate.year,
          record.startDate.month,
          record.startDate.day,
          5,
          15,
        ),
      ),
    );
  }

  _LicenseRecord _requireLicense(String organizationId) {
    final record = _records[organizationId];
    if (record == null) {
      throw ValidationException('This organization does not have a license.');
    }
    return record;
  }

  void _requireActivePlan(String planId) {
    if (_planById(planId).status != PlanStatus.active) {
      throw ValidationException('Select an active license plan.');
    }
  }

  void _requireValidTerm(DateTime start, DateTime expiry) {
    final error = OrganizationLicenseRules.termError(start, expiry);
    if (error != null) throw ValidationException(error);
  }

  void _requirePrices(double negotiated, double maintenance) {
    if (negotiated < 0 || maintenance < 0) {
      throw ValidationException('Prices cannot be negative.');
    }
  }

  void _addEvent(_LicenseRecord record, LicenseEventType type) {
    record.history.add(_event(record, type, now().toUtc()));
  }

  LicenseHistoryEvent _event(
    _LicenseRecord record,
    LicenseEventType type,
    DateTime at,
  ) {
    final plan = _planById(record.planId);
    return LicenseHistoryEvent(
      id: 'hist-${_nextNumber++}',
      eventType: type,
      eventAt: at,
      planId: plan.id,
      planCode: plan.planCode,
      planName: plan.name,
      planLevel: plan.level,
      maxStores: plan.maxStores,
      maxUsers: plan.maxUsers,
      startDate: record.startDate,
      expiryDate: record.expiryDate,
      negotiatedPrice: record.negotiatedPrice,
      maintenancePrice: record.maintenancePrice,
    );
  }

  OrganizationLicense _toLicense(_LicenseRecord record) {
    final plan = _planById(record.planId);
    return OrganizationLicense(
      id: record.id,
      organizationId: record.organizationId,
      startDate: record.startDate,
      expiryDate: record.expiryDate,
      negotiatedPrice: record.negotiatedPrice,
      maintenancePrice: record.maintenancePrice,
      status: _derivedStatus(record),
      plan: OrganizationLicensePlan(
        id: plan.id,
        planCode: plan.planCode,
        name: plan.name,
        level: plan.level,
        maxStores: plan.maxStores,
        maxUsers: plan.maxUsers,
        status: plan.status,
      ),
    );
  }

  OrganizationLicenseStatus _derivedStatus(_LicenseRecord record) {
    final today = _today();
    if (CalendarDate.daysBetween(today, record.startDate) > 0) {
      return OrganizationLicenseStatus.notYetActive;
    }
    final untilExpiry = CalendarDate.daysBetween(today, record.expiryDate);
    if (untilExpiry < 0) return OrganizationLicenseStatus.expired;
    if (untilExpiry <= OrganizationLicenseRules.renewalRecommendedWithinDays) {
      return OrganizationLicenseStatus.expiringSoon;
    }
    return OrganizationLicenseStatus.active;
  }

  bool _isUsableToday(_LicenseRecord record) {
    final today = _today();
    return _planById(record.planId).status == PlanStatus.active &&
        !today.isBefore(record.startDate) &&
        !today.isAfter(record.expiryDate);
  }

  DateTime _today() => CalendarDate.of(BusinessTime.dateOf(now()));

  LicensePlan _planById(String planId) =>
      _plans.firstWhere((plan) => plan.id == planId);

  static final List<LicensePlan> _catalogue = [
    LicensePlan(
      id: 'plan-basic',
      planCode: 'PLN-0A1B2C3D4E5F-BASIC',
      name: 'Basic',
      description: 'Single-store operations for small teams.',
      level: 1,
      maxStores: 3,
      maxUsers: 15,
      status: PlanStatus.active,
      assignedOrganizations: 0,
    ),
    LicensePlan(
      id: 'plan-plus',
      planCode: 'PLN-1A2B3C4D5E6F-PLUS',
      name: 'Plus',
      description: 'Multi-store operations for growing organizations.',
      level: 2,
      maxStores: 10,
      maxUsers: 50,
      status: PlanStatus.active,
      assignedOrganizations: 1,
    ),
    LicensePlan(
      id: 'plan-enterprise',
      planCode: 'PLN-2A2B3C4D5E6F-ENTERPRISE',
      name: 'Enterprise',
      description: 'Large networks with high user capacity.',
      level: 3,
      maxStores: 25,
      maxUsers: 200,
      status: PlanStatus.active,
      assignedOrganizations: 0,
    ),
    LicensePlan(
      id: 'plan-legacy',
      planCode: 'PLN-3A2B3C4D5E6F-LEGACY',
      name: 'Legacy Pilot',
      description: 'Retired pilot plan, kept for existing history.',
      level: 4,
      maxStores: 1,
      maxUsers: 5,
      status: PlanStatus.inactive,
      assignedOrganizations: 0,
    ),
  ];
}

/// Mutable license row inside the mock store.
class _LicenseRecord {
  _LicenseRecord({
    required this.id,
    required this.organizationId,
    required this.planId,
    required this.startDate,
    required this.expiryDate,
    required this.negotiatedPrice,
    required this.maintenancePrice,
  });

  final String id;
  final String organizationId;
  String planId;
  DateTime startDate;
  DateTime expiryDate;
  double negotiatedPrice;
  double maintenancePrice;
  final List<LicenseHistoryEvent> history = [];
}
