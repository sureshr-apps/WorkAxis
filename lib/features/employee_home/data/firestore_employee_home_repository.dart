import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/data/attendance_entry_mapper.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/services/attendance_location_provider.dart';

/// Production [EmployeeHomeRepository].
///
/// Reads the employee's own entry for today from `attendance_entries`
/// (queried by uid, as `firestore.rules` require). Punches are recorded only
/// through the `recordAttendancePunch` callable: the server stamps the time,
/// computes the business day and validates the geofence, so the client sends
/// just the action, the branch and its GPS fix.
class FirestoreEmployeeHomeRepository implements EmployeeHomeRepository {
  FirestoreEmployeeHomeRepository({
    FirebaseFirestore? firestore,
    CallableFunctions? functions,
    AttendanceLocationProvider? locationProvider,
    Now? now,
  }) : _customFirestore = firestore,
       _customFunctions = functions,
       _location =
           locationProvider ?? const UnavailableAttendanceLocationProvider(),
       _now = now ?? systemNow;

  /// Name of the punch callable (see `docs/backend-api.md`).
  static const String punchCallable = 'recordAttendancePunch';

  final FirebaseFirestore? _customFirestore;
  final CallableFunctions? _customFunctions;
  final AttendanceLocationProvider _location;
  final Now _now;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  CallableFunctions get _functions =>
      _customFunctions ?? FirebaseCallableFunctions();

  @override
  Future<EmployeeHomeSummary> getEmployeeHomeSummary({
    required UserAccessContext access,
  }) async {
    try {
      _requireEmployee(access);
      final entry = await _todayEntry(access.user.id);
      return await _summarize(access, entry);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<EmployeeHomeSummary> recordAttendanceAction({
    required UserAccessContext access,
    required AttendanceAction action,
  }) async {
    try {
      _requireEmployee(access);
      final branch = _punchBranch(access);
      final fix = await _location.currentLocation();
      await _functions.call(punchCallable, {
        'kind': _kind(action),
        'branchId': branch.id,
        'latitude': fix.latitude,
        'longitude': fix.longitude,
        'accuracyMeters': fix.accuracyMeters,
      });
      return await getEmployeeHomeSummary(access: access);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  void _requireEmployee(UserAccessContext access) {
    if (access.user.role != UserRole.employee) {
      throw const AccessDeniedException(
        'Employee home is only available to employees.',
      );
    }
    if (access.organization == null) {
      throw const AccessDeniedException('No organization context.');
    }
  }

  /// The branch a punch is recorded against: the active branch, or the only
  /// active assigned branch. Anything else is ambiguous and rejected.
  BranchSummary _punchBranch(UserAccessContext access) {
    final branch = _displayBranch(access);
    if (branch == null || !branch.isActive) {
      throw const BranchAuthorizationException(
        'No single active branch for the employee.',
        userMessage: 'You are not assigned to an active branch.',
      );
    }
    return branch;
  }

  BranchSummary? _displayBranch(UserAccessContext access) {
    final activeId = access.activeBranch?.branchId;
    if (activeId != null) {
      return access.assignedBranches.where((b) => b.id == activeId).firstOrNull;
    }
    final active = access.activeAssignedBranches;
    return active.length == 1 ? active.single : null;
  }

  Future<Map<String, dynamic>?> _todayEntry(String uid) async {
    final key = BusinessTime.keyOfInstant(_now());
    final snapshot = await _firestore
        .collection('attendance_entries')
        .where('employeeId', isEqualTo: uid)
        .where('workDateString', isEqualTo: key)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.data();
  }

  static const double _earthRadiusMeters = 6371000.0;

  static double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    double toRad(double deg) => (deg * math.pi) / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.asin(math.min(1.0, math.sqrt(a)));
    return _earthRadiusMeters * c;
  }

  Future<EmployeeHomeSummary> _summarize(
    UserAccessContext access,
    Map<String, dynamic>? entry,
  ) async {
    final checkIn = AttendanceEntryMapper.instant(entry?['checkInAt']);
    final checkOut = AttendanceEntryMapper.instant(entry?['checkOutAt']);
    final breaks = _breaks(entry?['breaks']);
    final onBreak = breaks.any((b) => b.end == null);

    final status = checkOut != null
        ? AttendanceStatus.checkedOut
        : onBreak
        ? AttendanceStatus.onBreak
        : checkIn != null
        ? AttendanceStatus.checkedIn
        : AttendanceStatus.notCheckedIn;

    final worked = checkIn == null
        ? null
        : _worked(checkIn, checkOut ?? _now(), breaks);
    final recordedByManager = entry?['source'] == 'manager-group';

    final branch = _displayBranch(access);
    bool isWithinGeofence = checkIn != null;
    String locationStatus = checkIn != null
        ? 'Location verified at check-in'
        : 'Location is verified when you check in';

    if (checkIn == null &&
        branch != null &&
        branch.latitude != null &&
        branch.longitude != null) {
      try {
        final fix = await _location
            .currentLocation()
            .timeout(const Duration(seconds: 4));
        final distance = _distanceMeters(
          fix.latitude,
          fix.longitude,
          branch.latitude!,
          branch.longitude!,
        );
        final radius = branch.geofenceRadiusMeters ?? 150;
        isWithinGeofence = distance <= radius;
        if (isWithinGeofence) {
          locationStatus = 'Inside geofence • Ready to check in';
        } else {
          locationStatus =
              'Outside geofence (${distance.round()}m away, radius: ${radius}m)';
        }
      } catch (_) {
        // Location permission denied, service disabled, or timed out.
      }
    }

    const standardShiftSeconds = 8 * 3600;
    final progress = worked == null
        ? 0.0
        : (worked.inSeconds / standardShiftSeconds).clamp(0.0, 1.0);

    return EmployeeHomeSummary(
      employeeId: access.user.id,
      employeeName: access.user.name,
      branchName:
          branch?.name ?? EmployeeHomeSummary.unavailable,
      organizationName: access.organization!.name,
      shiftName: EmployeeHomeSummary.unavailable,
      shiftHours: EmployeeHomeSummary.unavailable,
      standardDuration: '8h 00m',
      currentStatus: status,
      checkInTime: AppFormatters.formatTime(checkIn, placeholder: '-- : --'),
      checkInNote: recordedByManager ? 'Recorded by your manager' : null,
      checkOutTime: AppFormatters.formatTime(checkOut, placeholder: '-- : --'),
      workingDuration: worked == null ? '0h 00m' : _formatDuration(worked),
      shiftProgress: progress,
      locationStatus: locationStatus,
      isWithinGeofence: isWithinGeofence,
      latitude: branch?.latitude,
      longitude: branch?.longitude,
      geofenceRadiusMeters: branch?.geofenceRadiusMeters,
    );
  }

  List<({DateTime start, DateTime? end})> _breaks(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final b in raw.whereType<Map>())
        (
          start: AttendanceEntryMapper.instant(b['startAt']) ?? _now(),
          end: AttendanceEntryMapper.instant(b['endAt']),
        ),
    ];
  }

  Duration _worked(
    DateTime start,
    DateTime end,
    List<({DateTime start, DateTime? end})> breaks,
  ) {
    var total = end.difference(start);
    for (final b in breaks) {
      total -= (b.end ?? end).difference(b.start);
    }
    return total.isNegative ? Duration.zero : total;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes % 60;
    return '${d.inHours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String _kind(AttendanceAction action) => switch (action) {
    AttendanceAction.checkIn => 'checkIn',
    AttendanceAction.startBreak => 'breakStart',
    AttendanceAction.endBreak => 'breakEnd',
    AttendanceAction.checkOut => 'checkOut',
  };
}
