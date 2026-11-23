/// How a leave request would be paid if it were approved now.
///
/// Only scheduled working days count. Days within the remaining allowance of
/// the type are paid; the rest are unpaid and deducted from salary.
class LeavePreview {
  const LeavePreview({
    required this.leaveTypeId,
    required this.availableDays,
    required this.workdays,
    required this.paidDays,
    required this.unpaidDays,
  });

  final String leaveTypeId;

  /// Whole days of the type left on the start date.
  final int availableDays;

  /// Scheduled working days the request covers.
  final int workdays;
  final int paidDays;
  final int unpaidDays;

  bool get hasUnpaidDays => unpaidDays > 0;

  @override
  bool operator ==(Object other) =>
      other is LeavePreview &&
      other.leaveTypeId == leaveTypeId &&
      other.availableDays == availableDays &&
      other.workdays == workdays &&
      other.paidDays == paidDays &&
      other.unpaidDays == unpaidDays;

  @override
  int get hashCode =>
      Object.hash(leaveTypeId, availableDays, workdays, paidDays, unpaidDays);

  @override
  String toString() =>
      'LeavePreview($leaveTypeId, available: $availableDays, '
      'workdays: $workdays, paid: $paidDays, unpaid: $unpaidDays)';
}
