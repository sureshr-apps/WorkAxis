/// Overtime wording shared by payroll cards: potential hours are shown next
/// to approved hours, and only approved hours are paid.
abstract final class PayrollOvertimeLabels {
  static const String paidNote = 'Only approved overtime is paid.';

  /// e.g. `1.50 of 2.00 h approved`.
  static String approvedOfPotential(
    double approved,
    double potential, {
    int decimals = 2,
  }) =>
      '${approved.toStringAsFixed(decimals)} of '
      '${potential.toStringAsFixed(decimals)} h approved';

  /// KPI footer, e.g. `2.0 h potential · ₹245.29 paid`.
  static String potentialAndPaid(double potential, String paidAmount) =>
      '${potential.toStringAsFixed(1)} h potential · $paidAmount paid';
}
