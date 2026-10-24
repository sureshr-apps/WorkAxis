import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';

/// In-memory mock data source for Employee Home matching Stitch design.
class MockEmployeeHomeDataSource {
  AttendanceStatus _currentStatus = AttendanceStatus.checkedIn;
  String _employeeName = 'Marcus Vance';
  String _branchName = 'Central Distribution Hub';

  void setEmployeeContext({String? name, String? branch}) {
    if (name != null) _employeeName = name;
    if (branch != null) _branchName = branch;
  }

  void setStatus(AttendanceStatus status) {
    _currentStatus = status;
  }

  EmployeeHomeSummary getSummary() {
    String checkIn;
    String? checkInNote;
    String checkOut;
    String? checkOutNote;
    String elapsed;
    String elapsedPct;
    double progress;

    switch (_currentStatus) {
      case AttendanceStatus.notCheckedIn:
        checkIn = '-- : --';
        checkInNote = 'Shift starts 08:00 AM';
        checkOut = '-- : --';
        checkOutNote = 'Scheduled 05:00 PM';
        elapsed = '0h 00m';
        elapsedPct = '0% complete';
        progress = 0.0;
        break;
      case AttendanceStatus.checkedIn:
        checkIn = '07:54 AM';
        checkInNote = 'Early 6m';
        checkOut = '-- : --';
        checkOutNote = 'Pending exit';
        elapsed = '5h 42m';
        elapsedPct = '71% complete';
        progress = 0.712;
        break;
      case AttendanceStatus.onBreak:
        checkIn = '07:54 AM';
        checkInNote = 'Break started 12:30 PM';
        checkOut = '-- : --';
        checkOutNote = 'Pending exit';
        elapsed = '4h 36m (Active)';
        elapsedPct = 'Break: 0h 24m elapsed';
        progress = 0.575;
        break;
      case AttendanceStatus.checkedOut:
        checkIn = '07:54 AM';
        checkInNote = 'Compliant';
        checkOut = '05:02 PM';
        checkOutNote = 'Verified Outbound';
        elapsed = '8h 08m';
        elapsedPct = '100% complete (+8m OT)';
        progress = 1.0;
        break;
    }

    return EmployeeHomeSummary(
      employeeId: 'emp-1042',
      employeeName: _employeeName,
      branchName: _branchName,
      organizationName: 'Apex Logistics & Freight',
      shiftCode: 'CH-001',
      shiftName: 'Morning Shift',
      shiftHours: '08:00 AM – 05:00 PM',
      standardDuration: '8h 00m',
      terminalId: 'CH-TERM-09',
      currentStatus: _currentStatus,
      checkInTime: checkIn,
      checkInNote: checkInNote,
      checkOutTime: checkOut,
      checkOutNote: checkOutNote,
      workingDuration: elapsed,
      shiftProgress: progress,
      elapsedActive: elapsed,
      elapsedActivePercentText: elapsedPct,
      locationStatus: 'Location ready • Inside Branch Geofence',
      isWithinGeofence: true,
      geofenceId: 'GEO-CENTRAL-01',
      geofenceZone: 'Zone B • Outbound Logistics Corridor',
      networkMac: 'B4:F2:79:A1:09',
      syncRate: '1000ms',
      badgeAuth: 'NFC Verified',
      supervisorName: 'Rajesh Kumar',
      supervisorRole: 'Logistics Operations • Ext. 408',
      supervisorInitials: 'RK',
      assignedStationCode: 'BAY-SORT-04',
      assignedStationName: 'Primary Conveyor Tier 1 • Automated Induction',
      monthlyDaysPresent: 21,
      monthlyDaysLate: 1,
      monthlyDaysAbsent: 0,
      monthlyAdherencePercentage: 98,
      pendingReturnsCount: 1,
      approvedReturnsCount: 4,
      recentReturnTitle: 'Safety Helmet & High-Vis Vest Replacement',
      recentReturnSubtitle: 'Size L • Ticket #RET-8841 • Submitted Oct 24',
      recentReturnOffice: 'Terminal QM Office',
      recentReturnStatus: 'Pending Approval',
    );
  }

  void recordAction(AttendanceAction action) {
    switch (action) {
      case AttendanceAction.checkIn:
        _currentStatus = AttendanceStatus.checkedIn;
        break;
      case AttendanceAction.startBreak:
        _currentStatus = AttendanceStatus.onBreak;
        break;
      case AttendanceAction.endBreak:
        _currentStatus = AttendanceStatus.checkedIn;
        break;
      case AttendanceAction.checkOut:
        _currentStatus = AttendanceStatus.checkedOut;
        break;
    }
  }
}
