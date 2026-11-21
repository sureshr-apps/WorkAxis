/// Inclusive calendar dates selected for a custom operational report.
///
/// The repository converts these business-calendar dates into a half-open
/// timestamp range before querying the backend.
class ReportDateRange {
  ReportDateRange({required DateTime startDate, required DateTime endDate})
    : startDate = DateTime(startDate.year, startDate.month, startDate.day),
      endDate = DateTime(endDate.year, endDate.month, endDate.day);

  final DateTime startDate;
  final DateTime endDate;

  bool get isValid => !endDate.isBefore(startDate);

  @override
  bool operator ==(Object other) =>
      other is ReportDateRange &&
      startDate == other.startDate &&
      endDate == other.endDate;

  @override
  int get hashCode => Object.hash(startDate, endDate);
}
