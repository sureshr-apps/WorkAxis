import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';

/// Stable repository contract for Employee Home operations. Everything is
/// scoped to the signed-in employee in [UserAccessContext].
abstract interface class EmployeeHomeRepository {
  /// Today's summary for the employee in [access].
  Future<EmployeeHomeSummary> getEmployeeHomeSummary({
    required UserAccessContext access,
  });

  /// Records an attendance action and returns the refreshed summary. The
  /// server stamps the time and validates the geofence.
  Future<EmployeeHomeSummary> recordAttendanceAction({
    required UserAccessContext access,
    required AttendanceAction action,
  });
}
