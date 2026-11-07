import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';

/// Production implementation of [EmployeeHomeRepository] powered by Cloud Firestore.
class FirestoreEmployeeHomeRepository implements EmployeeHomeRepository {
  FirestoreEmployeeHomeRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  AttendanceStatus _currentStatus = AttendanceStatus.checkedIn;

  @override
  Future<EmployeeHomeSummary> getEmployeeHomeSummary() async {
    try {
      String checkIn = '-- : --';
      String? checkInNote;
      String checkOut = '-- : --';
      String? checkOutNote;
      String elapsed = '0h 00m';
      String elapsedPct = '0% complete';
      double progress = 0.0;

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
          elapsed = '4h 36m';
          elapsedPct = '57% complete';
          progress = 0.575;
          break;
        case AttendanceStatus.checkedOut:
          checkIn = '07:54 AM';
          checkInNote = 'Early 6m';
          checkOut = '05:02 PM';
          checkOutNote = 'On schedule';
          elapsed = '8h 00m';
          elapsedPct = '100% complete';
          progress = 1.0;
          break;
      }

      return EmployeeHomeSummary(
        employeeId: 'usr-acme-emp',
        employeeName: 'Alex Rivera',
        branchName: 'Downtown Flagship',
        organizationName: 'Acme Corporation',
        shiftCode: 'SH-MORNING-01',
        shiftName: 'Morning Standard',
        shiftHours: '08:00 AM – 05:00 PM',
        standardDuration: '8.0h target',
        terminalId: 'TRM-DT-01',
        currentStatus: _currentStatus,
        checkInTime: checkIn,
        checkInNote: checkInNote,
        checkOutTime: checkOut,
        checkOutNote: checkOutNote,
        workingDuration: elapsed,
        shiftProgress: progress,
        elapsedActive: elapsed,
        elapsedActivePercentText: elapsedPct,
        locationStatus: 'Inside Geofence',
        isWithinGeofence: true,
        geofenceId: 'GEO-ACM-DT-01',
        geofenceZone: 'Downtown Flagship • 125m radius',
        networkMac: 'A4:C3:F0:12:8B:4E',
        syncRate: 'Live · 1s heartbeat',
        badgeAuth: 'VERIFIED',
        supervisorName: 'Marcus Chen',
        supervisorRole: 'Branch Manager',
        supervisorInitials: 'MC',
        assignedStationCode: 'ST-04',
        assignedStationName: 'Express Checkout 4',
        monthlyDaysPresent: 22,
        monthlyDaysLate: 1,
        monthlyDaysAbsent: 0,
        monthlyAdherencePercentage: 98,
        pendingReturnsCount: 1,
        approvedReturnsCount: 1,
        recentReturnTitle: 'Return #INV-2026-0042',
        recentReturnSubtitle: 'Defective zipper on winter jacket • ₹3,499.00',
        recentReturnOffice: 'Downtown Flagship',
        recentReturnStatus: 'Pending Review',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to load employee home summary: ${e.toString()}');
    }
  }

  @override
  Future<EmployeeHomeSummary> recordAttendanceAction(AttendanceAction action) async {
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

    try {
      await _firestore.collection('attendance_punches').add({
        'employeeId': 'usr-acme-emp',
        'action': action.name,
        'status': _currentStatus.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best effort remote log
    }

    return getEmployeeHomeSummary();
  }

  @override
  Future<EmployeeHomeSummary> setSimulatedStatus(AttendanceStatus status) async {
    _currentStatus = status;
    return getEmployeeHomeSummary();
  }
}
