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
  });

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
    );
  }
}
