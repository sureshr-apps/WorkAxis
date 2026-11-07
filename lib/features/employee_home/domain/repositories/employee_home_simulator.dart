import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';

/// Debug-only capability to force an attendance status for demos. Implemented
/// by the mock repository only; production repositories must never implement
/// it, and the UI shows the simulator only when the repository does and the
/// app runs in debug mode.
abstract interface class EmployeeHomeSimulator {
  Future<EmployeeHomeSummary> setSimulatedStatus(AttendanceStatus status);
}
