/// Attendance controls exposed to the signed-in employee by a trusted callable.
class EmployeeAttendancePolicy {
  const EmployeeAttendancePolicy({
    required this.requireAttendanceSelfie,
    required this.requireGeolocation,
    required this.allowBreaks,
    required this.defaultGeofenceRadiusMeters,
  });

  static const defaults = EmployeeAttendancePolicy(
    requireAttendanceSelfie: true,
    requireGeolocation: true,
    allowBreaks: true,
    defaultGeofenceRadiusMeters: 150,
  );

  final bool requireAttendanceSelfie;
  final bool requireGeolocation;
  final bool allowBreaks;
  final int defaultGeofenceRadiusMeters;
}
