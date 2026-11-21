import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employee_home/data/mock_employee_home_data_source.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_policy.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_simulator.dart';

/// Mock repository for Employee Home. It is the only implementation of
/// [EmployeeHomeSimulator], so demo controls can never reach production.
class MockEmployeeHomeRepository
    implements EmployeeHomeRepository, EmployeeHomeSimulator {
  final MockEmployeeHomeDataSource dataSource;
  final Duration delay;
  final bool requireBranchManagerAttendanceByDefault;
  final bool Function(String organizationId)? branchManagerAttendanceLookup;

  MockEmployeeHomeRepository({
    MockEmployeeHomeDataSource? dataSource,
    this.delay = const Duration(milliseconds: 300),
    this.requireBranchManagerAttendanceByDefault = false,
    this.branchManagerAttendanceLookup,
  }) : dataSource = dataSource ?? MockEmployeeHomeDataSource();

  Future<void> _latency() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  /// Uses the signed-in self-service user's identity, including an enabled
  /// Branch Manager, rather than the mock's seeded employee identity.
  void _applyIdentity(UserAccessContext access) {
    if (access.user.role != UserRole.employee &&
        access.user.role != UserRole.branchManager) {
      throw const AccessDeniedException(
        'Self-service attendance is only available to employees and Branch Managers.',
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
    bool requestLocationPermission = false,
  }) async {
    _applyIdentity(access);
    _requireBranchManagerAttendance(access);
    await _latency();
    return dataSource.getSummary();
  }

  @override
  Future<EmployeeAttendancePolicy> getAttendancePolicy({
    required UserAccessContext access,
  }) async {
    _applyIdentity(access);
    await _latency();
    final managerAttendanceEnabled = _managerAttendanceEnabled(access);
    // The mock organization has selfie verification disabled so sample
    // attendance actions remain usable without invoking the camera plugin.
    return EmployeeAttendancePolicy(
      requireAttendanceSelfie: false,
      requireGeolocation: true,
      allowBreaks: true,
      defaultGeofenceRadiusMeters: 150,
      requireBranchManagerAttendance: managerAttendanceEnabled,
    );
  }

  @override
  Future<EmployeeHomeSummary> recordAttendanceAction({
    required UserAccessContext access,
    required AttendanceAction action,
    EmployeeAttendancePolicy? policy,
    String? selfieLocalPath,
  }) async {
    _applyIdentity(access);
    _requireBranchManagerAttendance(access);
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

  void _requireBranchManagerAttendance(UserAccessContext access) {
    if (access.user.role == UserRole.branchManager &&
        !_managerAttendanceEnabled(access)) {
      throw const AccessDeniedException(
        'Branch Manager attendance is disabled by the organization.',
      );
    }
  }

  bool _managerAttendanceEnabled(UserAccessContext access) {
    final organizationId =
        access.organization?.id ?? access.user.organizationId;
    if (organizationId == null) return requireBranchManagerAttendanceByDefault;
    return branchManagerAttendanceLookup?.call(organizationId) ??
        requireBranchManagerAttendanceByDefault;
  }
}
