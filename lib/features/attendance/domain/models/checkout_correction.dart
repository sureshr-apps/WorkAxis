import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// An employee's request to correct a missing or late check-out. A manager
/// approves (the requested time becomes the check-out) or rejects it.
class CheckoutCorrection {
  const CheckoutCorrection({
    required this.id,
    required this.entryId,
    required this.organizationId,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.workDate,
    required this.requestedCheckOutAt,
    required this.reason,
    required this.status,
    this.checkInAt,
    this.recordedCheckOutAt,
    this.createdAt,
    this.reviewedBy,
    this.reviewNote,
  });

  final String id;
  final String entryId;
  final String organizationId;
  final String branchId;
  final String employeeId;
  final String employeeName;

  /// The shift date of the corrected session.
  final DateTime workDate;
  final DateTime? checkInAt;

  /// The late check-out recorded before the correction (null when missing).
  final DateTime? recordedCheckOutAt;
  final DateTime requestedCheckOutAt;
  final String reason;
  final CorrectionStatus status;
  final DateTime? createdAt;
  final String? reviewedBy;
  final String? reviewNote;
}

enum CorrectionDecision { approve, reject }

enum OvertimeDecision { approve, reject }
