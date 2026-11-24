import 'dart:developer' as developer;
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
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart'
    hide AttendanceStatus;
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employee_home/data/employee_session_day_reader.dart';
import 'package:workaxis/features/employee_home/domain/models/attendance_session.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_policy.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/models/location_peek.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/services/attendance_location_provider.dart';
import 'package:workaxis/features/employee_home/domain/services/monthly_attendance_summary_calculator.dart';
import 'package:workaxis/features/employees/domain/models/employee_workforce_history.dart';
import 'package:workaxis/features/employees/domain/repositories/employee_workforce_repository.dart';
import 'package:workaxis/features/returns/domain/models/return_status_counts.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';

/// Production [EmployeeHomeRepository].
///
/// Reads the signed-in user's own entries from `attendance_entries` (queried
/// by uid, as `firestore.rules` require): today's, or the shift day of a
/// session still open after midnight (see [EmployeeSessionDayReader]).
/// Punches are recorded only
/// through the `recordAttendancePunch` callable: the server stamps the time,
/// computes the business day and validates the geofence. When required, the
/// client uploads a selfie and sends its storage reference with the punch.
class FirestoreEmployeeHomeRepository implements EmployeeHomeRepository {
  FirestoreEmployeeHomeRepository({
    FirebaseFirestore? firestore,
    CallableFunctions? functions,
    this._selfieStorage,
    AttendanceLocationProvider? locationProvider,
    this._workforceRepository,
    this._returnsRepository,
    Now? now,
  }) : _customFirestore = firestore,
       _customFunctions = functions,
       _location =
           locationProvider ?? const UnavailableAttendanceLocationProvider(),
       _now = now ?? systemNow {
    _sessions = EmployeeSessionDayReader(
      firestore: () => _firestore,
      now: _now,
    );
  }

  /// Name of the punch callable (see `docs/backend-api.md`).
  static const String punchCallable = 'recordAttendancePunch';
  static const String attendancePolicyCallable = 'getAttendanceSelfiePolicy';

  final FirebaseFirestore? _customFirestore;
  final CallableFunctions? _customFunctions;
  final ScopedAttachmentStorage? _selfieStorage;
  final AttendanceLocationProvider _location;
  final EmployeeWorkforceRepository? _workforceRepository;
  final ReturnsRepository? _returnsRepository;
  final Now _now;
  late final EmployeeSessionDayReader _sessions;

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
      _requireAttendanceUser(access);
      final policyFuture = _fetchAttendancePolicy();
      final dayFuture = _sessions.read(access.user.id);
      final monthlyEntriesFuture = _monthlyEntries(access.user.id);
      final policy = await policyFuture;
      _requireManagerAttendanceEnabled(access, policy);
      final returnCountsFuture = _loadOwnReturnCounts(access);
      final day = await dayFuture;
      final monthlyEntries = await monthlyEntriesFuture;
      return await _summarize(
        access,
        day,
        monthlyEntries: monthlyEntries,
        policy: policy,
        requestLocationPermission: requestLocationPermission,
        returnCounts: await returnCountsFuture,
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
      _requireAttendanceUser(access);
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
      _requireAttendanceUser(access);
      // The open session may belong to yesterday's shift (a night shift
      // after midnight); the server finds it the same way.
      final day = await _sessions.read(access.user.id);
      final selectedBranch = _punchBranch(access);
      final sessionBranch = _branchForEntry(access, day.openEntry);
      if (access.user.role == UserRole.employee &&
          action != AttendanceAction.checkIn &&
          sessionBranch != null &&
          selectedBranch.id != sessionBranch.id) {
        throw BranchAuthorizationException(
          'The selected branch does not match the open attendance session.',
          userMessage:
              'Switch back to ${sessionBranch.name} to finish this attendance session.',
        );
      }
      final branch = action == AttendanceAction.checkIn
          ? selectedBranch
          : sessionBranch ?? selectedBranch;
      final attendancePolicy = policy ?? await _fetchAttendancePolicy();
      _requireManagerAttendanceEnabled(access, attendancePolicy);
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
      requireBranchManagerAttendance: readPolicyFlag(
        'requireBranchManagerAttendance',
        EmployeeAttendancePolicy.defaults.requireBranchManagerAttendance,
      ),
    );
  }

  void _requireAttendanceUser(UserAccessContext access) {
    if (access.user.role != UserRole.employee &&
        access.user.role != UserRole.branchManager) {
      throw const AccessDeniedException(
        'Self-service attendance is only available to employees and Branch Managers.',
      );
    }
    if (access.organization == null) {
      throw const AccessDeniedException('No organization context.');
    }
  }

  void _requireManagerAttendanceEnabled(
    UserAccessContext access,
    EmployeeAttendancePolicy policy,
  ) {
    if (access.user.role == UserRole.branchManager &&
        !policy.requireBranchManagerAttendance) {
      throw const AccessDeniedException(
        'Branch Manager attendance is disabled by your organization.',
      );
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

  Future<List<AttendanceEntry>?> _monthlyEntries(String uid) async {
    final today = BusinessTime.today(_now);
    final startKey = BusinessTime.keyOfDate(DateTime(today.year, today.month));
    final endKey = BusinessTime.keyOfDate(today);
    try {
      final snapshot = await _firestore
          .collection('attendance_entries')
          .where('employeeId', isEqualTo: uid)
          .where('workDateString', isGreaterThanOrEqualTo: startKey)
          .where('workDateString', isLessThanOrEqualTo: endKey)
          .orderBy('workDateString')
          .get();
      return snapshot.docs
          .map(
            (document) =>
                AttendanceEntryMapper.fromData(document.id, document.data()),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      developer.log(
        'Unable to load monthly attendance entries for Employee Home.',
        name: 'workaxis.employee_home',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  BranchSummary? _branchForEntry(
    UserAccessContext access,
    SessionDayEntry? entry,
  ) {
    final branchId = entry?.data['branchId'];
    if (branchId is! String) return null;
    return access.assignedBranches
        .where((branch) => branch.id == branchId)
        .firstOrNull;
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
    SessionDay day, {
    required List<AttendanceEntry>? monthlyEntries,
    required EmployeeAttendancePolicy policy,
    required bool requestLocationPermission,
    required ({int pending, int approved})? returnCounts,
  }) async {
    final entries = day.entries;
    final current = day.current;
    final checkIn = current?.checkInAt;
    final checkOut = current?.checkOutAt;
    // A session the system closed has no check-out and is no longer running.
    final missingCheckOut = current?.closedWithoutCheckOut ?? false;
    final breaks = _breaks(current?.data['breaks']);
    final onBreak = !missingCheckOut && breaks.any((b) => b.end == null);

    final status = checkOut != null || missingCheckOut
        ? AttendanceStatus.checkedOut
        : onBreak
        ? AttendanceStatus.onBreak
        : checkIn != null
        ? AttendanceStatus.checkedIn
        : AttendanceStatus.notCheckedIn;

    final recordedByManager = current?.data['source'] == 'manager-group';

    final activeSession = day.openEntry;
    final branch = activeSession == null
        ? _displayBranch(access)
        : _branchForEntry(access, activeSession);
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
    List<ScheduleVersion>? scheduleHistory;
    try {
      final workforceRepository = _workforceRepository;
      if (workforceRepository != null) {
        final history = await workforceRepository.getHistory(
          access: access,
          memberId: '',
          activeBranchId: access.activeBranch?.branchId,
        );
        scheduleHistory = history.schedules;
        // The schedule of the shift day shown, which is yesterday while an
        // overnight session is still open.
        final dayKey = day.dayKey;
        final schedule = history.schedules.where((version) {
          final from = _dateKey(version.effectiveFrom);
          final to = version.effectiveTo == null
              ? null
              : _dateKey(version.effectiveTo!);
          return from.compareTo(dayKey) <= 0 &&
              (to == null || dayKey.compareTo(to) < 0);
        }).firstOrNull;
        if (schedule != null) {
          dailyWorkHours = schedule.dailyWorkHours;
          shiftHours = schedule.shiftHours;
        }
      }
    } catch (error, stackTrace) {
      // Defaults keep the dashboard usable if history is not yet backfilled.
      developer.log(
        'Unable to load workforce history for Employee Home.',
        name: 'workaxis.employee_home',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final MonthlyAttendanceMetrics monthlyMetrics =
        monthlyEntries == null || scheduleHistory == null
        ? MonthlyAttendanceSummaryCalculator.unavailable
        : MonthlyAttendanceSummaryCalculator.calculate(
            today: BusinessTime.today(_now),
            schedules: scheduleHistory,
            entries: monthlyEntries,
          );

    final totalMinutes = (dailyWorkHours * 60).round();
    final stdHours = totalMinutes ~/ 60;
    final stdMins = totalMinutes % 60;
    final standardDuration =
        '${stdHours}h ${stdMins.toString().padLeft(2, '0')}m';

    final standardShiftSeconds = (dailyWorkHours * 3600).round();
    final currentIndex = current == null ? -1 : entries.indexOf(current);
    var previousWorkedSeconds = 0;
    var totalWorked = Duration.zero;
    for (var index = 0; index < entries.length; index++) {
      final duration = _workedDuration(entries[index], _now());
      totalWorked += duration;
      if (index != currentIndex) previousWorkedSeconds += duration.inSeconds;
    }
    final session = checkIn == null || missingCheckOut
        ? null
        : AttendanceSession(
            checkIn: checkIn,
            checkOut: checkOut,
            breaks: [
              for (final b in breaks)
                AttendanceBreak(start: b.start, end: b.end),
            ],
            standardSeconds: standardShiftSeconds,
            workedBeforeSeconds: previousWorkedSeconds,
          );
    final worked = session?.workedAt(_now()) ?? totalWorked;
    final progress = session?.progressAt(_now()) ?? 0.0;

    return EmployeeHomeSummary(
      employeeId: access.user.id,
      employeeName: access.user.name,
      branchId: branch?.id,
      branchName: branch?.name ?? EmployeeHomeSummary.unavailable,
      organizationName: access.organization!.name,
      shiftName: EmployeeHomeSummary.unavailable,
      shiftHours: shiftHours,
      standardDuration: standardDuration,
      currentStatus: status,
      checkInTime: AppFormatters.formatTime(checkIn, placeholder: '-- : --'),
      checkInNote: recordedByManager ? 'Recorded by your manager' : null,
      checkOutTime: AppFormatters.formatTime(checkOut, placeholder: '-- : --'),
      checkOutNote: missingCheckOut ? 'Check-out missing' : null,
      workingDuration: AttendanceSession.formatDuration(worked),
      shiftProgress: progress,
      elapsedActive: AttendanceSession.formatDuration(worked),
      elapsedActivePercentText:
          '${(progress * 100).toStringAsFixed(0)}% complete',
      locationStatus: locationStatus,
      isWithinGeofence: isWithinGeofence,
      requireGeolocation: policy.requireGeolocation,
      allowBreaks: policy.allowBreaks,
      pendingReturnsCount: returnCounts?.pending,
      approvedReturnsCount: returnCounts?.approved,
      monthlyDaysPresent: monthlyMetrics.present,
      monthlyDaysLate: monthlyMetrics.late,
      monthlyDaysAbsent: monthlyMetrics.absent,
      monthlyAdherencePercentage: monthlyMetrics.adherencePercentage,
      latitude: branch?.latitude,
      longitude: branch?.longitude,
      geofenceRadiusMeters: branch == null
          ? null
          : (branch.geofenceRadiusMeters != null &&
                    branch.geofenceRadiusMeters! > 0
                ? branch.geofenceRadiusMeters
                : policy.defaultGeofenceRadiusMeters),
      session: session,
      attendanceEntry: current?.toAttendanceEntry(),
    );
  }

  Future<({int pending, int approved})?> _loadOwnReturnCounts(
    UserAccessContext access,
  ) async {
    final repository = _returnsRepository;
    if (repository == null) return null;

    try {
      // Server totals of the caller's own returns (a Branch Manager's own
      // queue in the active branch), without loading the list.
      final counts = await repository.getReturnCounts(
        access: access,
        queue: ReturnQueue.mine,
      );
      return (pending: counts.pending, approved: counts.approved);
    } catch (error, stackTrace) {
      developer.log(
        'Unable to load the signed-in user’s return counts for Employee Home.',
        name: 'workaxis.employee_home',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
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

  /// Worked time of one session. A session closed without a check-out counts
  /// nothing until a correction supplies the real check-out.
  Duration _workedDuration(SessionDayEntry entry, DateTime now) {
    final start = entry.checkInAt;
    if (start == null || entry.closedWithoutCheckOut) return Duration.zero;
    final end = entry.checkOutAt ?? now;
    var worked = end.difference(start);
    for (final pause in _breaks(entry.data['breaks'])) {
      final pauseEnd = pause.end ?? end;
      if (!pause.start.isAfter(end)) {
        worked -= pauseEnd.isAfter(end)
            ? end.difference(pause.start)
            : pauseEnd.difference(pause.start);
      }
    }
    return worked.isNegative ? Duration.zero : worked;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _kind(AttendanceAction action) => switch (action) {
    AttendanceAction.checkIn => 'checkIn',
    AttendanceAction.startBreak => 'breakStart',
    AttendanceAction.endBreak => 'breakEnd',
    AttendanceAction.checkOut => 'checkOut',
  };
}
