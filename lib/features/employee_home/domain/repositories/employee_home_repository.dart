import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';

/// Stable repository contract for Employee Home operations. Everything is
/// scoped to the signed-in employee in [UserAccessContext].
abstract interface class EmployeeHomeRepository {
  /// Today's summary for the employee in [access].
  ///
  /// Loading never shows the OS location-permission prompt. Pass
  /// [requestLocationPermission] only from an explicit user action (such as
  /// tapping the location refresh button) to allow the prompt.
  Future<EmployeeHomeSummary> getEmployeeHomeSummary({
    required UserAccessContext access,
    bool requestLocationPermission = false,
  });

  /// Whether the organization currently requires a new selfie for punches.
  /// Employees retrieve this value through a trusted callable rather than
  /// reading the full organization settings document.
  Future<bool> isAttendanceSelfieRequired({required UserAccessContext access});

  /// Records an attendance action and returns the refreshed summary. The
  /// server stamps the time and validates the geofence.
  Future<EmployeeHomeSummary> recordAttendanceAction({
    required UserAccessContext access,
    required AttendanceAction action,
    String? selfieLocalPath,
  });
}
