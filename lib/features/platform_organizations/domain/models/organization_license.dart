import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Server-derived state of an organization license. The server computes it
/// from the license dates in the Asia/Kolkata business day; the client only
/// displays it and never recomputes it for enforcement.
enum OrganizationLicenseStatus {
  notAssigned,
  notYetActive,
  active,
  expiringSoon,
  expired,
}

/// The live plan row an organization license points at. Plan name, level and
/// limits always reflect the plan as it is defined now.
class OrganizationLicensePlan {
  const OrganizationLicensePlan({
    required this.id,
    required this.planCode,
    required this.name,
    required this.level,
    required this.maxStores,
    required this.maxUsers,
    required this.status,
  });

  final String id;
  final String planCode;
  final String name;
  final int level;
  final int maxStores;
  final int maxUsers;
  final PlanStatus status;

  bool get isActive => status == PlanStatus.active;
}

/// The single license of an organization (one row per organization).
///
/// [startDate] and [expiryDate] are calendar dates held as UTC midnight; see
/// `CalendarDate`. Prices are whole rupees entered in INR.
class OrganizationLicense {
  const OrganizationLicense({
    required this.id,
    required this.organizationId,
    required this.startDate,
    required this.expiryDate,
    required this.negotiatedPrice,
    required this.maintenancePrice,
    required this.status,
    required this.plan,
  });

  final String id;
  final String organizationId;
  final DateTime startDate;
  final DateTime expiryDate;

  /// One-time negotiated price in INR.
  final double negotiatedPrice;

  /// Yearly maintenance price in INR.
  final double maintenancePrice;

  final OrganizationLicenseStatus status;
  final OrganizationLicensePlan plan;
}
