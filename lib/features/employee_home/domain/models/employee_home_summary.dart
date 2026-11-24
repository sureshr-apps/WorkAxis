import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart'
    show AttendanceEntry;
import 'package:workaxis/features/employee_home/domain/models/attendance_session.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';

/// Typed dashboard metrics for Employee Home overview matching Stitch design.
///
/// Fields the backend cannot provide hold [unavailable] (text) or null
/// (counts); they are never filled with invented values.
class EmployeeHomeSummary {
  /// Placeholder shown for text the backend does not provide.
  static const String unavailable = '—';

  final String employeeId;
  final String employeeName;
  final String? branchId;
  final String branchName;
  final String organizationName;
  final String shiftCode;
  final String shiftName;
  final String shiftHours;
  final String standardDuration;
  final String terminalId;
  final AttendanceStatus currentStatus;
  final String? checkInTime;
  final String? checkInNote;
  final String? checkOutTime;
  final String? checkOutNote;
  final String workingDuration;
  final double shiftProgress;
  final String elapsedActive;
  final String elapsedActivePercentText;
  final String locationStatus;
  final bool isWithinGeofence;
  final bool requireGeolocation;
  final bool allowBreaks;
  final double? latitude;
  final double? longitude;
  final int? geofenceRadiusMeters;
  final String geofenceId;
  final String geofenceZone;
  final String networkMac;
  final String syncRate;
  final String badgeAuth;
  final String supervisorName;
  final String supervisorRole;
  final String supervisorInitials;
  final String assignedStationCode;
  final String assignedStationName;
  final int? monthlyDaysPresent;
  final int? monthlyDaysLate;
  final int? monthlyDaysAbsent;
  final int? monthlyAdherencePercentage;
  final int? pendingReturnsCount;
  final int? approvedReturnsCount;
  final String? recentReturnTitle;
  final String? recentReturnSubtitle;
  final String? recentReturnOffice;
  final String? recentReturnStatus;

  /// Backward-compatible alias for existing tests
  String? get recentReturnItem => recentReturnTitle;

  const EmployeeHomeSummary({
    required this.employeeId,
    required this.employeeName,
    this.branchId,
    required this.branchName,
    this.organizationName = unavailable,
    this.shiftCode = unavailable,
    required this.shiftName,
    required this.shiftHours,
    this.standardDuration = unavailable,
    this.terminalId = unavailable,
    required this.currentStatus,
    this.checkInTime,
    this.checkInNote,
    this.checkOutTime,
    this.checkOutNote,
    required this.workingDuration,
    required this.shiftProgress,
    this.elapsedActive = unavailable,
    this.elapsedActivePercentText = unavailable,
    required this.locationStatus,
    required this.isWithinGeofence,
    this.requireGeolocation = true,
    this.allowBreaks = true,
    this.latitude,
    this.longitude,
    this.geofenceRadiusMeters,
    this.geofenceId = unavailable,
    this.geofenceZone = unavailable,
    this.networkMac = unavailable,
    this.syncRate = unavailable,
    this.badgeAuth = unavailable,
    this.supervisorName = unavailable,
    this.supervisorRole = unavailable,
    this.supervisorInitials = unavailable,
    this.assignedStationCode = unavailable,
    this.assignedStationName = unavailable,
    this.monthlyDaysPresent,
    this.monthlyDaysLate,
    this.monthlyDaysAbsent,
    this.monthlyAdherencePercentage,
    this.pendingReturnsCount,
    this.approvedReturnsCount,
    this.recentReturnTitle,
    this.recentReturnSubtitle = unavailable,
    this.recentReturnOffice = unavailable,
    this.recentReturnStatus,
    String? recentReturnItem,
    this.session,
    this.attendanceEntry,
  });

  /// Today's attendance times, when the employee has checked in.
  final AttendanceSession? session;

  /// The attendance record shown (the open session, else the shift day's
  /// latest), with its scheduled shift and check-out deadlines.
  final AttendanceEntry? attendanceEntry;

  /// This summary with the running time measured at [now]. Only a session still
  /// in progress changes; anything else is returned as it is.
  EmployeeHomeSummary atTime(DateTime now) {
    final running = session;
    if (running == null || !running.isRunning) return this;
    final worked = running.workedAt(now);
    final progress = running.progressAt(now);
    final workedText = AttendanceSession.formatDuration(worked);
    return copyWith(
      workingDuration: workedText,
      elapsedActive: workedText,
      shiftProgress: progress,
      elapsedActivePercentText:
          '${(progress * 100).toStringAsFixed(0)}% complete',
    );
  }

  EmployeeHomeSummary copyWith({
    AttendanceStatus? currentStatus,
    String? checkInTime,
    String? checkInNote,
    String? checkOutTime,
    String? checkOutNote,
    String? workingDuration,
    double? shiftProgress,
    String? elapsedActive,
    String? elapsedActivePercentText,
    double? latitude,
    double? longitude,
    int? geofenceRadiusMeters,
    bool? requireGeolocation,
    bool? allowBreaks,
    int? pendingReturnsCount,
    int? approvedReturnsCount,
    String? recentReturnTitle,
    String? recentReturnSubtitle,
    String? recentReturnOffice,
    String? recentReturnStatus,
  }) {
    return EmployeeHomeSummary(
      employeeId: employeeId,
      employeeName: employeeName,
      branchId: branchId,
      branchName: branchName,
      organizationName: organizationName,
      shiftCode: shiftCode,
      shiftName: shiftName,
      shiftHours: shiftHours,
      standardDuration: standardDuration,
      terminalId: terminalId,
      currentStatus: currentStatus ?? this.currentStatus,
      checkInTime: checkInTime ?? this.checkInTime,
      checkInNote: checkInNote ?? this.checkInNote,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkOutNote: checkOutNote ?? this.checkOutNote,
      workingDuration: workingDuration ?? this.workingDuration,
      shiftProgress: shiftProgress ?? this.shiftProgress,
      elapsedActive: elapsedActive ?? this.elapsedActive,
      elapsedActivePercentText:
          elapsedActivePercentText ?? this.elapsedActivePercentText,
      locationStatus: locationStatus,
      isWithinGeofence: isWithinGeofence,
      requireGeolocation: requireGeolocation ?? this.requireGeolocation,
      allowBreaks: allowBreaks ?? this.allowBreaks,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      geofenceId: geofenceId,
      geofenceZone: geofenceZone,
      networkMac: networkMac,
      syncRate: syncRate,
      badgeAuth: badgeAuth,
      supervisorName: supervisorName,
      supervisorRole: supervisorRole,
      supervisorInitials: supervisorInitials,
      assignedStationCode: assignedStationCode,
      assignedStationName: assignedStationName,
      monthlyDaysPresent: monthlyDaysPresent,
      monthlyDaysLate: monthlyDaysLate,
      monthlyDaysAbsent: monthlyDaysAbsent,
      monthlyAdherencePercentage: monthlyAdherencePercentage,
      pendingReturnsCount: pendingReturnsCount ?? this.pendingReturnsCount,
      approvedReturnsCount: approvedReturnsCount ?? this.approvedReturnsCount,
      recentReturnTitle: recentReturnTitle ?? this.recentReturnTitle,
      recentReturnSubtitle: recentReturnSubtitle ?? this.recentReturnSubtitle,
      recentReturnOffice: recentReturnOffice ?? this.recentReturnOffice,
      recentReturnStatus: recentReturnStatus ?? this.recentReturnStatus,
      session: session,
      attendanceEntry: attendanceEntry,
    );
  }
}
