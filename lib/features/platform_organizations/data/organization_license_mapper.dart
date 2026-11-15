import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Converts license payloads between the `dataOp` wire format and the domain
/// models. Calendar dates travel as `yyyy-MM-dd` strings; unknown enum values
/// are malformed responses, never silently mapped.
abstract final class OrganizationLicenseMapper {
  // ---- Responses ---------------------------------------------------------

  static OrganizationLicense license(Map<String, dynamic> json) =>
      OrganizationLicense(
        id: json.string('id'),
        organizationId: json.string('organizationId'),
        startDate: _calendarDate(json, 'startDate'),
        expiryDate: _calendarDate(json, 'expiryDate'),
        negotiatedPrice: json.number('negotiatedPrice'),
        maintenancePrice: json.number('maintenancePrice'),
        status: _licenseStatus(json.string('status')),
        plan: _licensePlanReference(json.object('plan')),
      );

  static LicenseHistoryEvent historyEvent(Map<String, dynamic> json) =>
      LicenseHistoryEvent(
        id: json.string('id'),
        eventType: _eventType(json.string('eventType')),
        eventAt: json.dateTime('eventAt'),
        planId: json.string('planId'),
        planCode: json.string('planCode'),
        planName: json.string('planName'),
        planLevel: json.integer('planLevel'),
        maxStores: json.integer('maxStores'),
        maxUsers: json.integer('maxUsers'),
        startDate: _calendarDate(json, 'startDate'),
        expiryDate: _calendarDate(json, 'expiryDate'),
        negotiatedPrice: json.number('negotiatedPrice'),
        maintenancePrice: json.number('maintenancePrice'),
      );

  /// One row of `ListLicensePlans`.
  static LicensePlan licensePlan(Map<String, dynamic> json) => LicensePlan(
    id: json.string('id'),
    planCode: json.string('planCode'),
    name: json.string('name'),
    description: json.optString('description') ?? '',
    level: json.integer('level'),
    maxStores: json.integer('maxStores'),
    maxUsers: json.integer('maxUsers'),
    status: planStatus(json.string('status')),
    assignedOrganizations: json.integer('assignedOrganizations'),
  );

  /// Wire value of a plan status. Unknown values read as inactive, so malformed
  /// data never makes a plan assignable.
  static PlanStatus planStatus(String wire) => PlanStatus.fromString(wire);

  // ---- Request variables -------------------------------------------------

  /// Variables of `ListLicensePlans`. Unset filters are omitted, never null.
  static Map<String, dynamic> listLicensePlansVars({PlanStatus? status}) => {
    if (status != null) 'status': status.name,
  };

  static Map<String, dynamic> organizationVars(String organizationId) => {
    'organizationId': organizationId,
  };

  static Map<String, dynamic> assignVars(
    String organizationId,
    AssignLicenseRequest request,
  ) => {
    'organizationId': organizationId,
    'planId': request.planId,
    'startDate': CalendarDate.format(request.startDate),
    'expiryDate': CalendarDate.format(request.expiryDate),
    'negotiatedPrice': request.negotiatedPrice,
    'maintenancePrice': request.maintenancePrice,
  };

  static Map<String, dynamic> changePlanVars(
    String organizationId,
    ChangeLicensePlanRequest request,
  ) => {
    'organizationId': organizationId,
    'targetPlanId': request.targetPlanId,
    'negotiatedPrice': request.negotiatedPrice,
    'maintenancePrice': request.maintenancePrice,
  };

  static Map<String, dynamic> modifyCommercialTermsVars(
    String organizationId,
    ModifyCommercialTermsRequest request,
  ) => {
    'organizationId': organizationId,
    'negotiatedPrice': request.negotiatedPrice,
    'maintenancePrice': request.maintenancePrice,
  };

  static Map<String, dynamic> renewVars(
    String organizationId,
    RenewLicenseRequest request,
  ) => {
    'organizationId': organizationId,
    'planId': request.planId,
    'newStartDate': CalendarDate.format(request.newStartDate),
    'newExpiryDate': CalendarDate.format(request.newExpiryDate),
    'negotiatedPrice': request.negotiatedPrice,
    'maintenancePrice': request.maintenancePrice,
  };

  // ---- Helpers -----------------------------------------------------------

  static OrganizationLicensePlan _licensePlanReference(
    Map<String, dynamic> json,
  ) => OrganizationLicensePlan(
    id: json.string('id'),
    planCode: json.string('planCode'),
    name: json.string('name'),
    level: json.integer('level'),
    maxStores: json.integer('maxStores'),
    maxUsers: json.integer('maxUsers'),
    status: planStatus(json.string('status')),
  );

  static DateTime _calendarDate(Map<String, dynamic> json, String key) {
    final date = CalendarDate.tryParse(json.string(key));
    if (date == null) {
      throw DatabaseException('Malformed response: "$key" must be a date.');
    }
    return date;
  }

  static OrganizationLicenseStatus _licenseStatus(String wire) =>
      switch (wire) {
        'not_assigned' => OrganizationLicenseStatus.notAssigned,
        'not_yet_active' => OrganizationLicenseStatus.notYetActive,
        'active' => OrganizationLicenseStatus.active,
        'expiring_soon' => OrganizationLicenseStatus.expiringSoon,
        'expired' => OrganizationLicenseStatus.expired,
        _ => throw DatabaseException(
          'Malformed response: unknown license status.',
        ),
      };

  static LicenseEventType _eventType(String wire) => switch (wire) {
    'assigned' => LicenseEventType.assigned,
    'plan_changed' => LicenseEventType.planChanged,
    'commercial_terms_modified' => LicenseEventType.commercialTermsModified,
    'renewed' => LicenseEventType.renewed,
    _ => throw DatabaseException('Malformed response: unknown license event.'),
  };
}
