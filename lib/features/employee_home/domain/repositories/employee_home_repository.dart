import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';

/// Stable repository contract for Employee Home operations.
abstract interface class EmployeeHomeRepository {
  /// Fetches daily operational summary for the signed-in employee.
  Future<EmployeeHomeSummary> getEmployeeHomeSummary();

  /// Records an attendance action (e.g., check in, start break, check out) and returns updated summary.
  Future<EmployeeHomeSummary> recordAttendanceAction(AttendanceAction action);

  /// Sets simulated attendance status for frontline demo / verification.
  Future<EmployeeHomeSummary> setSimulatedStatus(AttendanceStatus status);
}
