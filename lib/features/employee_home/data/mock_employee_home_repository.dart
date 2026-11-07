import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employee_home/data/mock_employee_home_data_source.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_simulator.dart';

/// Mock repository for Employee Home. It is the only implementation of
/// [EmployeeHomeSimulator], so demo controls can never reach production.
class MockEmployeeHomeRepository
    implements EmployeeHomeRepository, EmployeeHomeSimulator {
  final MockEmployeeHomeDataSource dataSource;
  final Duration delay;

  MockEmployeeHomeRepository({
    MockEmployeeHomeDataSource? dataSource,
    this.delay = const Duration(milliseconds: 300),
  }) : dataSource = dataSource ?? MockEmployeeHomeDataSource();

  Future<void> _latency() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  /// Mirrors production: employees only, with the identity taken from [access].
  void _applyIdentity(UserAccessContext access) {
    if (access.user.role != UserRole.employee) {
      throw const AccessDeniedException(
        'Employee home is only available to employees.',
      );
    }
    final branch =
        access.activeBranch?.branchName ??
        (access.assignedBranches.isNotEmpty
            ? access.assignedBranches.first.name
            : null);
    dataSource.setEmployeeContext(name: access.user.name, branch: branch);
  }

  @override
  Future<EmployeeHomeSummary> getEmployeeHomeSummary({
    required UserAccessContext access,
  }) async {
    _applyIdentity(access);
    await _latency();
    return dataSource.getSummary();
  }

  @override
  Future<EmployeeHomeSummary> recordAttendanceAction({
    required UserAccessContext access,
    required AttendanceAction action,
  }) async {
    _applyIdentity(access);
    await _latency();
    dataSource.recordAction(action);
    return dataSource.getSummary();
  }

  @override
  Future<EmployeeHomeSummary> setSimulatedStatus(
    AttendanceStatus status,
  ) async {
    await _latency();
    dataSource.setStatus(status);
    return dataSource.getSummary();
  }
}
