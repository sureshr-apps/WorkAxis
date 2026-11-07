/// Reporting window selectable on the Operational Reports screen.
enum ReportPeriod {
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  quarterToDate('Quarter to Date');

  const ReportPeriod(this.label);

  /// Display label.
  final String label;
}
