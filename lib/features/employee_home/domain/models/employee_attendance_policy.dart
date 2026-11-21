/// Self-service attendance controls returned by a trusted callable.
class EmployeeAttendancePolicy {
  const EmployeeAttendancePolicy({
    required this.requireAttendanceSelfie,
    required this.requireGeolocation,
    required this.allowBreaks,
    required this.defaultGeofenceRadiusMeters,
    this.requireBranchManagerAttendance = false,
  });

  static const defaults = EmployeeAttendancePolicy(
    requireAttendanceSelfie: true,
    requireGeolocation: true,
    allowBreaks: true,
    defaultGeofenceRadiusMeters: 150,
    requireBranchManagerAttendance: false,
  );

  final bool requireAttendanceSelfie;
  final bool requireGeolocation;
  final bool allowBreaks;
  final int defaultGeofenceRadiusMeters;
  final bool requireBranchManagerAttendance;
}
