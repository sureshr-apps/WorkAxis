import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';

abstract interface class AttendanceRepository {
  /// Entries for the business [date] (a calendar date in the business
  /// timezone; the time of day is ignored), scoped by [access]: employees see
  /// only their own, Branch Managers only an active assigned branch, Org
  /// Admins their organization. Platform users have no attendance scope.
  Future<List<AttendanceEntry>> getAttendance({
    required UserAccessContext access,
    required DateTime date,
    String? activeBranchId,
    String? employeeId,
  });

  Future<AttendanceEntry> reviewException({
    required UserAccessContext access,
    required String entryId,
    required String activeBranchId,
    required AttendanceReviewDecision decision,
  });

  /// Records a manager group check-in. The server validates the selected
  /// effective time and records a separate server audit timestamp.
  Future<List<AttendanceEntry>> markGroupAttendance({
    required UserAccessContext access,
    required GroupAttendanceRequest request,
  });
}
