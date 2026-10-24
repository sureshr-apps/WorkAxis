enum AttendanceStatus { present, late, absent, incomplete }

enum AttendanceReviewStatus { none, needsReview, verified, dismissed }

enum AttendanceReviewDecision { verify, dismiss }

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
    this.note,
    this.kioskEntry = false,
  });

  final String id;
  final String organizationId;
  final String branchId;
  final String employeeId;
  final String employeeName;
  final DateTime workDate;
  final AttendanceStatus status;
  final AttendanceReviewStatus reviewStatus;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String? note;
  final bool kioskEntry;

  AttendanceEntry copyWith({AttendanceReviewStatus? reviewStatus}) =>
      AttendanceEntry(
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
        note: note,
        kioskEntry: kioskEntry,
      );
}
