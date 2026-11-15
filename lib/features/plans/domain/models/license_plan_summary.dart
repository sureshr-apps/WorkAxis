/// Catalogue-wide counts shown on the Plans summary cards.
class LicensePlanSummary {
  const LicensePlanSummary({
    required this.totalPlans,
    required this.activePlans,
    required this.inactivePlans,
    required this.assignedOrganizations,
  });

  static const LicensePlanSummary empty = LicensePlanSummary(
    totalPlans: 0,
    activePlans: 0,
    inactivePlans: 0,
    assignedOrganizations: 0,
  );

  final int totalPlans;
  final int activePlans;
  final int inactivePlans;

  /// Organizations that hold a license (on any plan).
  final int assignedOrganizations;
}
