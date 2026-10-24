import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';

/// Typed dashboard metrics for Employee Home overview matching Stitch design.
class EmployeeHomeSummary {
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
  final int monthlyDaysPresent;
  final int monthlyDaysLate;
  final int monthlyDaysAbsent;
  final int monthlyAdherencePercentage;
  final int pendingReturnsCount;
  final int approvedReturnsCount;
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
    this.organizationName = 'Apex Logistics & Freight',
    this.shiftCode = 'CH-001',
    required this.shiftName,
    required this.shiftHours,
    this.standardDuration = '8h 00m',
    this.terminalId = 'CH-TERM-09',
    required this.currentStatus,
    this.checkInTime,
    this.checkInNote,
    this.checkOutTime,
    this.checkOutNote,
    required this.workingDuration,
    required this.shiftProgress,
    this.elapsedActive = '5h 42m',
    this.elapsedActivePercentText = '71% complete',
    required this.locationStatus,
    required this.isWithinGeofence,
    this.geofenceId = 'GEO-CENTRAL-01',
    this.geofenceZone = 'Zone B • Outbound Logistics Corridor',
    this.networkMac = 'B4:F2:79:A1:09',
    this.syncRate = '1000ms',
    this.badgeAuth = 'NFC Verified',
    this.supervisorName = 'Rajesh Kumar',
    this.supervisorRole = 'Logistics Operations • Ext. 408',
    this.supervisorInitials = 'RK',
    this.assignedStationCode = 'BAY-SORT-04',
    this.assignedStationName = 'Primary Conveyor Tier 1 • Automated Induction',
    required this.monthlyDaysPresent,
    required this.monthlyDaysLate,
    required this.monthlyDaysAbsent,
    required this.monthlyAdherencePercentage,
    required this.pendingReturnsCount,
    this.approvedReturnsCount = 4,
    this.recentReturnTitle,
    this.recentReturnSubtitle = 'Size L • Ticket #RET-8841 • Submitted Oct 24',
    this.recentReturnOffice = 'Terminal QM Office',
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
