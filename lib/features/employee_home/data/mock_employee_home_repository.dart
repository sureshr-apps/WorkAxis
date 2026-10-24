import 'package:workaxis/features/employee_home/data/mock_employee_home_data_source.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';

/// Mock repository implementation for Employee Home operations.
class MockEmployeeHomeRepository implements EmployeeHomeRepository {
  final MockEmployeeHomeDataSource dataSource;
  final Duration delay;

  MockEmployeeHomeRepository({
    MockEmployeeHomeDataSource? dataSource,
    this.delay = const Duration(milliseconds: 300),
  }) : dataSource = dataSource ?? MockEmployeeHomeDataSource();

  @override
  Future<EmployeeHomeSummary> getEmployeeHomeSummary() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getSummary();
  }

  @override
  Future<EmployeeHomeSummary> recordAttendanceAction(
    AttendanceAction action,
  ) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    dataSource.recordAction(action);
    return dataSource.getSummary();
  }

  @override
  Future<EmployeeHomeSummary> setSimulatedStatus(
    AttendanceStatus status,
  ) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    dataSource.setStatus(status);
    return dataSource.getSummary();
  }
}
