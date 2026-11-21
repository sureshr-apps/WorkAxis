import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/data/attendance_entry_mapper.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employee_home/domain/models/attendance_session.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_policy.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/models/location_peek.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/services/attendance_location_provider.dart';

/// Production [EmployeeHomeRepository].
///
/// Reads the employee's own entry for today from `attendance_entries`
/// (queried by uid, as `firestore.rules` require). Punches are recorded only
/// through the `recordAttendancePunch` callable: the server stamps the time,
/// computes the business day and validates the geofence. When required, the
/// client uploads a selfie and sends its storage reference with the punch.
class FirestoreEmployeeHomeRepository implements EmployeeHomeRepository {
  FirestoreEmployeeHomeRepository({
    FirebaseFirestore? firestore,
    CallableFunctions? functions,
    this._selfieStorage,
    AttendanceLocationProvider? locationProvider,
    Now? now,
  }) : _customFirestore = firestore,
       _customFunctions = functions,
       _location =
           locationProvider ?? const UnavailableAttendanceLocationProvider(),
       _now = now ?? systemNow;

  /// Name of the punch callable (see `docs/backend-api.md`).
  static const String punchCallable = 'recordAttendancePunch';
  static const String attendancePolicyCallable = 'getAttendanceSelfiePolicy';

  final FirebaseFirestore? _customFirestore;
  final CallableFunctions? _customFunctions;
  final ScopedAttachmentStorage? _selfieStorage;
  final AttendanceLocationProvider _location;
  final Now _now;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  CallableFunctions get _functions =>
      _customFunctions ?? FirebaseCallableFunctions();

  @override
  Future<EmployeeHomeSummary> getEmployeeHomeSummary({
    required UserAccessContext access,
    bool requestLocationPermission = false,
  }) async {
    try {
      _requireEmployee(access);
      final policy = await _fetchAttendancePolicy();
      final entry = await _todayEntry(access.user.id);
      return await _summarize(
        access,
        entry,
        policy: policy,
        requestLocationPermission: requestLocationPermission,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<EmployeeAttendancePolicy> getAttendancePolicy({
    required UserAccessContext access,
  }) async {
    try {
      _requireEmployee(access);
      return await _fetchAttendancePolicy();
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<EmployeeHomeSummary> recordAttendanceAction({
    required UserAccessContext access,
    required AttendanceAction action,
    EmployeeAttendancePolicy? policy,
    String? selfieLocalPath,
  }) async {
    try {
      _requireEmployee(access);
      final branch = _punchBranch(access);
      final attendancePolicy = policy ?? await _fetchAttendancePolicy();
      String? selfiePath;
      if (selfieLocalPath != null) {
        final storage = _selfieStorage;
        if (storage == null) {
          throw const DatabaseException(
            'Attendance selfie storage is not configured.',
            userMessage: 'A selfie could not be saved. Please try again or contact your administrator.',
          );
        }
        selfiePath = await storage.uploadScoped(
          localPath: selfieLocalPath,
          organizationId: access.organization!.id,
          kind: AttachmentKind.attendanceSelfie,
          pathSegments: [branch.id, access.user.id],
        );
      }
      final payload = <String, dynamic>{
        'kind': _kind(action),
        'branchId': branch.id,
      };
      if (attendancePolicy.requireGeolocation) {
        final fix = await _location.currentLocation();
        payload['latitude'] = fix.latitude;
        payload['longitude'] = fix.longitude;
        payload['accuracyMeters'] = fix.accuracyMeters;
      }
      if (selfiePath != null) payload['selfiePath'] = selfiePath;
      await _functions.call(punchCallable, payload);
      return await getEmployeeHomeSummary(access: access);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  Future<EmployeeAttendancePolicy> _fetchAttendancePolicy() async {
    final response = await _functions.call(attendancePolicyCallable);
    final requireSelfie = response['requireAttendanceSelfie'];
    if (requireSelfie is! bool) {
      throw const DatabaseException(
        'Attendance policy returned an invalid selfie requirement.',
        userMessage: 'Attendance settings could not be checked. Try again before recording attendance.',
      );
    }

    bool readPolicyFlag(String key, bool fallback) {
      final value = response[key];
      return value is bool ? value : fallback;
    }

    final configuredRadius = response['defaultGeofenceRadiusMeters'];
    final defaultRadius =
        configuredRadius is num &&
            configuredRadius.isFinite &&
            configuredRadius > 0
        ? configuredRadius.round()
        : EmployeeAttendancePolicy.defaults.defaultGeofenceRadiusMeters;

    return EmployeeAttendancePolicy(
      requireAttendanceSelfie: requireSelfie,
      requireGeolocation: readPolicyFlag(
        'requireGeolocation',
        EmployeeAttendancePolicy.defaults.requireGeolocation,
      ),
      allowBreaks: readPolicyFlag(
        'allowBreaks',
        EmployeeAttendancePolicy.defaults.allowBreaks,
      ),
      defaultGeofenceRadiusMeters: defaultRadius,
    );
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
    Map<String, dynamic>? entry, {
    required EmployeeAttendancePolicy policy,
    required bool requestLocationPermission,
  }) async {
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

    final recordedByManager = entry?['source'] == 'manager-group';

    final branch = _displayBranch(access);
    bool isWithinGeofence = false;
    String locationStatus = policy.requireGeolocation
        ? (checkIn != null
              ? 'Location verified at check-in'
              : 'Location is verified when you check in')
        : 'GPS verification is disabled by your organization';

    if (policy.requireGeolocation && checkIn != null) {
      isWithinGeofence = true;
    } else if (policy.requireGeolocation &&
        checkIn == null &&
        branch != null &&
        branch.latitude != null &&
        branch.longitude != null) {
      final peek = await _readLocation(
        requestPermission: requestLocationPermission,
      );
      final fix = peek.fix;
      if (fix != null) {
        final distance = _distanceMeters(
          fix.latitude,
          fix.longitude,
          branch.latitude!,
          branch.longitude!,
        );
        final branchRadius = branch.geofenceRadiusMeters;
        final radius = branchRadius != null && branchRadius > 0
            ? branchRadius
            : policy.defaultGeofenceRadiusMeters;
        isWithinGeofence = distance <= radius;
        locationStatus = isWithinGeofence
            ? 'Inside geofence • Ready to check in'
            : 'Outside geofence (${distance.round()}m away, radius: ${radius}m)';
      } else {
        locationStatus = _locationOffStatus(peek.readiness);
      }
    }

    double dailyWorkHours = 8.0;
    String shiftHours = EmployeeHomeSummary.unavailable;
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(access.user.id)
          .get();
      final userData = userDoc.data();
      if (userData != null) {
        final hoursVal = userData['dailyWorkHours'];
        if (hoursVal is num && hoursVal > 0) {
          dailyWorkHours = hoursVal.toDouble();
        }
        final shiftVal = userData['shiftHours'];
        if (shiftVal is String && shiftVal.trim().isNotEmpty) {
          shiftHours = shiftVal.trim();
        }
      }
    } catch (_) {
      // Fallback to defaults if read fails or device is offline.
    }

    final totalMinutes = (dailyWorkHours * 60).round();
    final stdHours = totalMinutes ~/ 60;
    final stdMins = totalMinutes % 60;
    final standardDuration =
        '${stdHours}h ${stdMins.toString().padLeft(2, '0')}m';

    final standardShiftSeconds = (dailyWorkHours * 3600).round();
    final session = checkIn == null
        ? null
        : AttendanceSession(
            checkIn: checkIn,
            checkOut: checkOut,
            breaks: [
              for (final b in breaks)
                AttendanceBreak(start: b.start, end: b.end),
            ],
            standardSeconds: standardShiftSeconds,
          );
    final worked = session?.workedAt(_now());
    final progress = session?.progressAt(_now()) ?? 0.0;

    return EmployeeHomeSummary(
      employeeId: access.user.id,
      employeeName: access.user.name,
      branchName: branch?.name ?? EmployeeHomeSummary.unavailable,
      organizationName: access.organization!.name,
      shiftName: EmployeeHomeSummary.unavailable,
      shiftHours: shiftHours,
      standardDuration: standardDuration,
      currentStatus: status,
      checkInTime: AppFormatters.formatTime(checkIn, placeholder: '-- : --'),
      checkInNote: recordedByManager ? 'Recorded by your manager' : null,
      checkOutTime: AppFormatters.formatTime(checkOut, placeholder: '-- : --'),
      workingDuration: worked == null
          ? '0h 00m'
          : AttendanceSession.formatDuration(worked),
      shiftProgress: progress,
      elapsedActive: worked == null
          ? '-- : --'
          : AttendanceSession.formatDuration(worked),
      elapsedActivePercentText: worked == null
          ? EmployeeHomeSummary.unavailable
          : '${(progress * 100).toStringAsFixed(0)}% complete',
      locationStatus: locationStatus,
      isWithinGeofence: isWithinGeofence,
      requireGeolocation: policy.requireGeolocation,
      allowBreaks: policy.allowBreaks,
      latitude: branch?.latitude,
      longitude: branch?.longitude,
      geofenceRadiusMeters: branch == null
          ? null
          : (branch.geofenceRadiusMeters != null &&
                    branch.geofenceRadiusMeters! > 0
                ? branch.geofenceRadiusMeters
                : policy.defaultGeofenceRadiusMeters),
      session: session,
    );
  }

  /// Passive read by default (never prompts). Only an explicit user action
  /// ([requestPermission]) may trigger the OS permission dialog.
  Future<LocationPeek> _readLocation({required bool requestPermission}) async {
    const limit = Duration(seconds: 4);
    if (!requestPermission) {
      return _location.peekLocation().timeout(
        limit,
        onTimeout: () => const LocationPeek(LocationReadiness.unavailable),
      );
    }
    try {
      final fix = await _location.currentLocation().timeout(limit);
      return LocationPeek(LocationReadiness.ready, fix);
    } on LocationException catch (e) {
      return LocationPeek(switch (e.failure) {
        LocationFailure.serviceDisabled => LocationReadiness.serviceDisabled,
        LocationFailure.permissionDenied => LocationReadiness.permissionNeeded,
        LocationFailure.permissionDeniedForever =>
          LocationReadiness.permissionBlocked,
        _ => LocationReadiness.unavailable,
      });
    } catch (_) {
      return const LocationPeek(LocationReadiness.unavailable);
    }
  }

  String _locationOffStatus(LocationReadiness readiness) => switch (readiness) {
    LocationReadiness.permissionBlocked =>
      'Location blocked – enable it in settings to punch in',
    LocationReadiness.unavailable => 'Location unavailable – tap refresh',
    _ => 'Location off – enable to punch in',
  };

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

  String _kind(AttendanceAction action) => switch (action) {
    AttendanceAction.checkIn => 'checkIn',
    AttendanceAction.startBreak => 'breakStart',
    AttendanceAction.endBreak => 'breakEnd',
    AttendanceAction.checkOut => 'checkOut',
  };
}
