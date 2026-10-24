/// Attendance actions triggered from the employee interface.
enum AttendanceAction { checkIn, startBreak, endBreak, checkOut }

/// Current daily attendance status for an employee.
enum AttendanceStatus {
  notCheckedIn,
  checkedIn,
  onBreak,
  checkedOut;

  String get displayName {
    switch (this) {
      case AttendanceStatus.notCheckedIn:
        return 'Not Checked In';
      case AttendanceStatus.checkedIn:
        return 'Checked In';
      case AttendanceStatus.onBreak:
        return 'On Break';
      case AttendanceStatus.checkedOut:
        return 'Checked Out';
    }
  }

  String get nextActionLabel {
    switch (this) {
      case AttendanceStatus.notCheckedIn:
        return 'Check In';
      case AttendanceStatus.checkedIn:
        return 'Start Break';
      case AttendanceStatus.onBreak:
        return 'End Break';
      case AttendanceStatus.checkedOut:
        return 'Completed For Today';
    }
  }

  AttendanceAction? get nextAction {
    switch (this) {
      case AttendanceStatus.notCheckedIn:
        return AttendanceAction.checkIn;
      case AttendanceStatus.checkedIn:
        return AttendanceAction.startBreak;
      case AttendanceStatus.onBreak:
        return AttendanceAction.endBreak;
      case AttendanceStatus.checkedOut:
        return null;
    }
  }
}
