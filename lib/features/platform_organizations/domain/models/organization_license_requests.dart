/// Input for assigning the first license of an organization.
class AssignLicenseRequest {
  const AssignLicenseRequest({
    required this.planId,
    required this.startDate,
    required this.expiryDate,
    required this.negotiatedPrice,
    required this.maintenancePrice,
  });

  final String planId;
  final DateTime startDate;
  final DateTime expiryDate;
  final double negotiatedPrice;
  final double maintenancePrice;
}

/// Moves the license to a higher-level plan. Dates are unchanged.
class ChangeLicensePlanRequest {
  const ChangeLicensePlanRequest({
    required this.targetPlanId,
    required this.negotiatedPrice,
    required this.maintenancePrice,
  });

  final String targetPlanId;
  final double negotiatedPrice;
  final double maintenancePrice;
}

/// Changes prices only.
class ModifyCommercialTermsRequest {
  const ModifyCommercialTermsRequest({
    required this.negotiatedPrice,
    required this.maintenancePrice,
  });

  final double negotiatedPrice;
  final double maintenancePrice;
}

/// Starts a new term after the current expiry date.
class RenewLicenseRequest {
  const RenewLicenseRequest({
    required this.planId,
    required this.newStartDate,
    required this.newExpiryDate,
    required this.negotiatedPrice,
    required this.maintenancePrice,
  });

  final String planId;
  final DateTime newStartDate;
  final DateTime newExpiryDate;
  final double negotiatedPrice;
  final double maintenancePrice;
}
