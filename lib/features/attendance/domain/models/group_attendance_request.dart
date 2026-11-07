import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// Single attendee data for batch attendance marking.
class GroupAttendanceAttendee {
  const GroupAttendanceAttendee({
    required this.employeeId,
    required this.employeeName,
  });

  final String employeeId;
  final String employeeName;
}

/// Request model containing batch check-in configuration and attendee list.
class GroupAttendanceRequest {
  const GroupAttendanceRequest({
    required this.branchId,
    required this.workDate,
    required this.checkInAt,
    required this.attendees,
    this.shiftName = 'Morning Shift',
    this.status = AttendanceStatus.present,
    this.note,
  });

  final String branchId;
  final DateTime workDate;
  final DateTime checkInAt;
  final List<GroupAttendanceAttendee> attendees;
  final String shiftName;
  final AttendanceStatus status;
  final String? note;
}
