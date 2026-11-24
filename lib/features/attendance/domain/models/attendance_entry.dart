enum AttendanceStatus { present, late, absent, incomplete }

enum AttendanceReviewStatus { none, needsReview, verified, dismissed }

enum AttendanceReviewDecision { verify, dismiss }

/// Check-out state recorded by the server, separate from the scheduled shift
/// end and from the session expiry:
/// - [overdue]: the shift ended and the overtime allowance passed without a
///   check-out (the employee may still be working);
/// - [late]: checked out after the allowance, recorded but flagged;
/// - [missing]: the maximum session length passed and the system closed the
///   session without a check-out;
/// - [corrected]: a manager approved the employee's correction.
enum CheckoutStatus { none, overdue, late, missing, corrected }

/// Approval of hours worked beyond the schedule. Only approved hours are paid.
enum OvertimeStatus { none, pending, approved, rejected }

/// The employee's request to correct a missing or late check-out.
enum CorrectionStatus { none, pending, approved, rejected }

class AttendanceEntry {
  const AttendanceEntry({
    required this.id,
    required this.organizationId,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.workDate,
    required this.status,
    required this.reviewStatus,
    this.checkInAt,
    this.checkOutAt,
    this.checkInSelfiePath,
    this.checkOutSelfiePath,
    this.breaks = const [],
    this.note,
    this.kioskEntry = false,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.scheduledHours,
    this.checkoutReminderAt,
    this.checkoutOverdueAt,
    this.sessionExpiresAt,
    this.checkoutStatus = CheckoutStatus.none,
    this.sessionClosedAt,
    this.checkOutCorrected = false,
    this.potentialOvertimeHours = 0,
    this.overtimeStatus = OvertimeStatus.none,
    this.approvedOvertimeHours,
    this.correctionStatus = CorrectionStatus.none,
    this.correctionId,
  });

  final String id;
  final String organizationId;
  final String branchId;
  final String employeeId;
  final String employeeName;

  /// The shift date: a night shift keeps the day it started on.
  final DateTime workDate;
  final AttendanceStatus status;
  final AttendanceReviewStatus reviewStatus;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String? checkInSelfiePath;
  final String? checkOutSelfiePath;
  final List<AttendanceBreakRecord> breaks;
  final String? note;
  final bool kioskEntry;

  /// The scheduled shift this session belongs to (null when unscheduled).
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final double? scheduledHours;

  /// When the employee is reminded to check out, when the open session is
  /// flagged overdue, and when the system closes it.
  final DateTime? checkoutReminderAt;
  final DateTime? checkoutOverdueAt;
  final DateTime? sessionExpiresAt;
  final CheckoutStatus checkoutStatus;

  /// When the system closed the session for exceeding the maximum length.
  final DateTime? sessionClosedAt;

  /// The check-out time comes from an approved correction.
  final bool checkOutCorrected;

  /// Hours beyond the schedule credited to this session.
  final double potentialOvertimeHours;
  final OvertimeStatus overtimeStatus;
  final double? approvedOvertimeHours;
  final CorrectionStatus correctionStatus;
  final String? correctionId;

  /// Whether the session is still open (checked in, not checked out or closed).
  bool get isOpen =>
      checkInAt != null && checkOutAt == null && sessionClosedAt == null;

  AttendanceEntry copyWith({
    AttendanceReviewStatus? reviewStatus,
    OvertimeStatus? overtimeStatus,
    double? approvedOvertimeHours,
    CorrectionStatus? correctionStatus,
    String? correctionId,
  }) => AttendanceEntry(
    id: id,
    organizationId: organizationId,
    branchId: branchId,
    employeeId: employeeId,
    employeeName: employeeName,
    workDate: workDate,
    status: status,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    checkInAt: checkInAt,
    checkOutAt: checkOutAt,
    checkInSelfiePath: checkInSelfiePath,
    checkOutSelfiePath: checkOutSelfiePath,
    breaks: breaks,
    note: note,
    kioskEntry: kioskEntry,
    scheduledStartAt: scheduledStartAt,
    scheduledEndAt: scheduledEndAt,
    scheduledHours: scheduledHours,
    checkoutReminderAt: checkoutReminderAt,
    checkoutOverdueAt: checkoutOverdueAt,
    sessionExpiresAt: sessionExpiresAt,
    checkoutStatus: checkoutStatus,
    sessionClosedAt: sessionClosedAt,
    checkOutCorrected: checkOutCorrected,
    potentialOvertimeHours: potentialOvertimeHours,
    overtimeStatus: overtimeStatus ?? this.overtimeStatus,
    approvedOvertimeHours: overtimeStatus == OvertimeStatus.rejected
        ? null
        : approvedOvertimeHours ?? this.approvedOvertimeHours,
    correctionStatus: correctionStatus ?? this.correctionStatus,
    correctionId: correctionId ?? this.correctionId,
  );
}

class AttendanceBreakRecord {
  const AttendanceBreakRecord({
    required this.startAt,
    this.endAt,
    this.startSelfiePath,
    this.endSelfiePath,
  });

  final DateTime startAt;
  final DateTime? endAt;
  final String? startSelfiePath;
  final String? endSelfiePath;
}
