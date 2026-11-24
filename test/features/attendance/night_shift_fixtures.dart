/// Night-shift attendance fixtures shared by the attendance display tests.
library;

import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// Instants are written in UTC; Asia/Kolkata is UTC+05:30, so 15:30Z is
/// 9:00 PM business time whatever the machine's zone.
DateTime ist(int day, int hour, [int minute = 0]) => DateTime.utc(
  2026,
  11,
  day,
  hour,
  minute,
).subtract(const Duration(hours: 5, minutes: 30));

AttendanceEntry nightShift({
  String id = 'att-1',
  DateTime? checkOutAt,
  CheckoutStatus checkoutStatus = CheckoutStatus.none,
  DateTime? sessionClosedAt,
  bool checkOutCorrected = false,
  double potentialOvertimeHours = 0,
  OvertimeStatus overtimeStatus = OvertimeStatus.none,
  double? approvedOvertimeHours,
  CorrectionStatus correctionStatus = CorrectionStatus.none,
  List<AttendanceBreakRecord> breaks = const [],
}) => AttendanceEntry(
  id: id,
  organizationId: 'org-acme',
  branchId: 'br-01',
  employeeId: 'user-emp-01',
  employeeName: 'Sarah Connor',
  workDate: DateTime(2026, 11, 6),
  status: AttendanceStatus.present,
  reviewStatus: AttendanceReviewStatus.none,
  checkInAt: ist(6, 21),
  checkOutAt: checkOutAt,
  scheduledStartAt: ist(6, 21),
  scheduledEndAt: ist(7, 5),
  scheduledHours: 8,
  checkoutStatus: checkoutStatus,
  sessionClosedAt: sessionClosedAt,
  checkOutCorrected: checkOutCorrected,
  potentialOvertimeHours: potentialOvertimeHours,
  overtimeStatus: overtimeStatus,
  approvedOvertimeHours: approvedOvertimeHours,
  correctionStatus: correctionStatus,
  breaks: breaks,
);
