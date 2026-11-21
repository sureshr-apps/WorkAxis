import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employee_home/data/firestore_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/data/mock_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/models/device_location.dart';
import 'package:workaxis/features/employee_home/domain/models/location_peek.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/services/attendance_location_provider.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fixed_clock.dart';

class _FakeCallables implements CallableFunctions {
  final List<({String name, Map<String, dynamic> payload})> calls = [];
  Object? failWith;
  String? failOnName;
  VoidCallback? onCall;
  Map<String, dynamic> attendancePolicy = {
    'requireAttendanceSelfie': true,
    'requireGeolocation': true,
    'allowBreaks': true,
    'defaultGeofenceRadiusMeters': 150,
  };

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> payload = const {},
  ]) async {
    calls.add((name: name, payload: payload));
    if (failWith != null && (failOnName == null || failOnName == name)) {
      throw failWith!;
    }
    if (name == 'recordAttendancePunch') onCall?.call();
    if (name == 'getAttendanceSelfiePolicy') {
      return Map<String, dynamic>.of(attendancePolicy);
    }
    return const {};
  }
}

typedef VoidCallback = void Function();

class _FixedLocation implements AttendanceLocationProvider {
  _FixedLocation({this.readiness = LocationReadiness.ready});

  /// What a passive read reports; `ready` also yields the fixed fix.
  LocationReadiness readiness;
  int currentCalls = 0;
  int peekCalls = 0;

  static const _fix = DeviceLocation(
    latitude: 12.9716,
    longitude: 77.5946,
    accuracyMeters: 8,
  );

  @override
  Future<DeviceLocation> currentLocation() async {
    currentCalls++;
    return _fix;
  }

  @override
  Future<LocationPeek> peekLocation() async {
    peekCalls++;
    return LocationPeek(
      readiness,
      readiness == LocationReadiness.ready ? _fix : null,
    );
  }
}

Future<void> _entry(
  FakeFirebaseFirestore db, {
  required String employee,
  Map<String, dynamic> extra = const {},
}) => db.collection('attendance_entries').doc('${employee}_2026-11-07').set({
  'organizationId': 'org-acme',
  'branchId': 'br-01',
  'employeeId': employee,
  'employeeName': 'Name $employee',
  'workDateString': '2026-11-07',
  'status': 'present',
  ...extra,
});

void main() {
  late FakeFirebaseFirestore db;
  late _FakeCallables callables;
  late FirestoreEmployeeHomeRepository repo;
  final access = employeeAccess();

  Timestamp at(int utcHour, int minute) =>
      Timestamp.fromDate(DateTime.utc(2026, 11, 7, utcHour, minute));

  setUp(() {
    db = FakeFirebaseFirestore();
    callables = _FakeCallables();
    repo = FirestoreEmployeeHomeRepository(
      firestore: db,
      functions: callables,
      locationProvider: _FixedLocation(),
      now: fixedNow, // 10:30 IST = 05:00 UTC
    );
  });

  group('FirestoreEmployeeHomeRepository.getEmployeeHomeSummary', () {
    test(
      'no entry today means not checked in, with the caller\'s identity',
      () async {
        await _entry(
          db,
          employee: 'someone-else',
          extra: {'checkInAt': at(3, 0)},
        );

        final summary = await repo.getEmployeeHomeSummary(access: access);

        expect(summary.currentStatus, AttendanceStatus.notCheckedIn);
        expect(summary.employeeId, 'user-emp-01');
        expect(summary.employeeName, 'Sarah Connor');
        expect(summary.branchName, 'Downtown Flagship');
        expect(summary.organizationName, 'Apex Logistics & Freight');
        expect(summary.checkInTime, '-- : --');
      },
    );

    test('reads the employee\'s own check-in, never a colleague\'s', () async {
      await _entry(
        db,
        employee: 'someone-else',
        extra: {'checkInAt': at(1, 0)},
      );
      await _entry(db, employee: 'user-emp-01', extra: {'checkInAt': at(3, 0)});

      final summary = await repo.getEmployeeHomeSummary(access: access);

      expect(summary.currentStatus, AttendanceStatus.checkedIn);
      expect(summary.checkInTime, isNot('-- : --'));
      expect(summary.workingDuration, '2h 00m'); // 03:00Z -> 05:00Z
      expect(summary.isWithinGeofence, isTrue);
    });

    test(
      'open break means on break; breaks are excluded from worked time',
      () async {
        await _entry(
          db,
          employee: 'user-emp-01',
          extra: {
            'checkInAt': at(2, 0),
            'breaks': [
              {'startAt': at(3, 0), 'endAt': at(3, 30)},
              {'startAt': at(4, 30)},
            ],
          },
        );

        final summary = await repo.getEmployeeHomeSummary(access: access);

        expect(summary.currentStatus, AttendanceStatus.onBreak);
        // 3h since check-in minus 30m and the still-open 30m break.
        expect(summary.workingDuration, '2h 00m');
      },
    );

    test('check-out means checked out', () async {
      await _entry(
        db,
        employee: 'user-emp-01',
        extra: {'checkInAt': at(1, 0), 'checkOutAt': at(4, 0)},
      );
      final summary = await repo.getEmployeeHomeSummary(access: access);
      expect(summary.currentStatus, AttendanceStatus.checkedOut);
      expect(summary.workingDuration, '3h 00m');
    });

    test(
      'data the backend does not hold is marked unavailable, not invented',
      () async {
        final summary = await repo.getEmployeeHomeSummary(access: access);

        expect(summary.shiftName, EmployeeHomeSummary.unavailable);
        expect(summary.terminalId, EmployeeHomeSummary.unavailable);
        expect(summary.networkMac, EmployeeHomeSummary.unavailable);
        expect(summary.supervisorName, EmployeeHomeSummary.unavailable);
        expect(summary.monthlyDaysPresent, isNull);
        expect(summary.pendingReturnsCount, isNull);
        expect(summary.isWithinGeofence, isFalse);
        for (final fake in ['Alex Rivera', 'Marcus Vance', 'Rajesh Kumar']) {
          expect(summary.employeeName, isNot(fake));
          expect(summary.supervisorName, isNot(fake));
        }
      },
    );

    test('evaluates live geofence when branch has coordinates', () async {
      final geofenceBranch = BranchSummary(
        id: 'br-geo-01',
        organizationId: acmeOrg.id,
        name: 'Geofence Test Branch',
        code: 'GEO-01',
        location: 'City',
        latitude: 12.9716,
        longitude: 77.5946,
        geofenceRadiusMeters: 150,
      );
      final geofenceAccess = UserAccessContext(
        user: fixtureUser(
          UserRole.employee,
          id: 'user-emp-01',
          name: 'Sarah Connor',
        ),
        organization: acmeOrg,
        assignedBranches: [geofenceBranch],
        activeBranch: ActiveBranchContext.fromBranch(geofenceBranch),
      );

      final summary = await repo.getEmployeeHomeSummary(access: geofenceAccess);

      // _FixedLocation is at (12.9716, 77.5946), exactly at branch center
      expect(summary.isWithinGeofence, isTrue);
      expect(summary.locationStatus, contains('Inside geofence'));
    });

    test(
      'loading never prompts and shows an inline location-off state',
      () async {
        final location = _FixedLocation(
          readiness: LocationReadiness.permissionNeeded,
        );
        final locRepo = FirestoreEmployeeHomeRepository(
          firestore: db,
          functions: callables,
          locationProvider: location,
          now: fixedNow,
        );
        final branch = BranchSummary(
          id: 'br-geo-03',
          organizationId: acmeOrg.id,
          name: 'Prompt Branch',
          code: 'GEO-03',
          location: 'City',
          latitude: 12.9716,
          longitude: 77.5946,
          geofenceRadiusMeters: 150,
        );
        final geoAccess = UserAccessContext(
          user: fixtureUser(
            UserRole.employee,
            id: 'user-emp-01',
            name: 'Sarah Connor',
          ),
          organization: acmeOrg,
          assignedBranches: [branch],
          activeBranch: ActiveBranchContext.fromBranch(branch),
        );

        final summary = await locRepo.getEmployeeHomeSummary(access: geoAccess);

        expect(location.currentCalls, 0);
        expect(location.peekCalls, 1);
        expect(summary.isWithinGeofence, isFalse);
        expect(summary.locationStatus, contains('Location off'));

        // An explicit user action is the only path that may prompt.
        await locRepo.getEmployeeHomeSummary(
          access: geoAccess,
          requestLocationPermission: true,
        );
        expect(location.currentCalls, 1);
      },
    );

    test('evaluates outside geofence when device is far from branch', () async {
      final farBranch = BranchSummary(
        id: 'br-geo-02',
        organizationId: acmeOrg.id,
        name: 'Far Test Branch',
        code: 'GEO-02',
        location: 'City',
        latitude: 13.5000,
        longitude: 78.5000,
        geofenceRadiusMeters: 100,
      );
      final farAccess = UserAccessContext(
        user: fixtureUser(
          UserRole.employee,
          id: 'user-emp-01',
          name: 'Sarah Connor',
        ),
        organization: acmeOrg,
        assignedBranches: [farBranch],
        activeBranch: ActiveBranchContext.fromBranch(farBranch),
      );

      final summary = await repo.getEmployeeHomeSummary(access: farAccess);

      expect(summary.isWithinGeofence, isFalse);
      expect(summary.locationStatus, contains('Outside geofence'));
    });

    test(
      'uses the organization radius for a branch with no positive radius',
      () async {
        callables.attendancePolicy['defaultGeofenceRadiusMeters'] = 80;
        final branch = BranchSummary(
          id: 'br-default-radius',
          organizationId: acmeOrg.id,
          name: 'Default Radius Branch',
          code: 'DEF-01',
          location: 'City',
          latitude: 12.9716,
          longitude: 77.5946,
          geofenceRadiusMeters: 0,
        );
        final branchAccess = UserAccessContext(
          user: access.user,
          organization: acmeOrg,
          assignedBranches: [branch],
          activeBranch: ActiveBranchContext.fromBranch(branch),
        );

        final summary = await repo.getEmployeeHomeSummary(access: branchAccess);

        expect(summary.geofenceRadiusMeters, 80);
        expect(summary.locationStatus, contains('Inside geofence'));
      },
    );

    test(
      'does not request location when organization GPS verification is off',
      () async {
        callables.attendancePolicy['requireGeolocation'] = false;
        final location = _FixedLocation();
        final noGpsRepo = FirestoreEmployeeHomeRepository(
          firestore: db,
          functions: callables,
          locationProvider: location,
          now: fixedNow,
        );

        final summary = await noGpsRepo.getEmployeeHomeSummary(access: access);

        expect(location.peekCalls, 0);
        expect(summary.requireGeolocation, isFalse);
        expect(
          summary.locationStatus,
          contains('GPS verification is disabled'),
        );
      },
    );

    test('only employees may load it', () async {
      await expectLater(
        repo.getEmployeeHomeSummary(access: orgAdminAccess()),
        throwsA(isA<AccessDeniedException>()),
      );
    });
  });

  group('FirestoreEmployeeHomeRepository.recordAttendanceAction', () {
    test(
      'records through the callable with kind, branch and GPS fix only',
      () async {
        await repo.recordAttendanceAction(
          access: access,
          action: AttendanceAction.checkIn,
        );

        final call = callables.calls.singleWhere(
          (entry) => entry.name == 'recordAttendancePunch',
        );
        expect(call.name, 'recordAttendancePunch');
        expect(call.payload, {
          'kind': 'checkIn',
          'branchId': 'br-01',
          'latitude': 12.9716,
          'longitude': 77.5946,
          'accuracyMeters': 8.0,
        });
        expect(call.payload.containsKey('timestamp'), isFalse);
        expect(call.payload.containsKey('employeeId'), isFalse);
      },
    );

    test('maps every action to the server\'s punch kinds', () async {
      for (final (action, kind) in [
        (AttendanceAction.checkIn, 'checkIn'),
        (AttendanceAction.startBreak, 'breakStart'),
        (AttendanceAction.endBreak, 'breakEnd'),
        (AttendanceAction.checkOut, 'checkOut'),
      ]) {
        await repo.recordAttendanceAction(access: access, action: action);
        expect(
          callables.calls
              .lastWhere((entry) => entry.name == 'recordAttendancePunch')
              .payload['kind'],
          kind,
        );
      }
    });

    test('never writes to Firestore from the client', () async {
      await repo.recordAttendanceAction(
        access: access,
        action: AttendanceAction.checkIn,
      );
      expect((await db.collection('attendance_entries').get()).docs, isEmpty);
      expect((await db.collection('attendance_punches').get()).docs, isEmpty);
    });

    test(
      'returns the summary re-read after the server recorded the punch',
      () async {
        callables.onCall = () =>
            _entry(db, employee: 'user-emp-01', extra: {'checkInAt': at(4, 0)});
        final summary = await repo.recordAttendanceAction(
          access: access,
          action: AttendanceAction.checkIn,
        );
        expect(summary.currentStatus, AttendanceStatus.checkedIn);
      },
    );

    test('server rejections surface instead of reporting success', () async {
      callables.failWith = const AccessDeniedException(
        'Callable permission-denied',
        'You are outside the branch geofence.',
      );
      callables.failOnName = 'recordAttendancePunch';
      await expectLater(
        repo.recordAttendanceAction(
          access: access,
          action: AttendanceAction.checkIn,
        ),
        throwsA(
          isA<AccessDeniedException>().having(
            (e) => e.userMessage,
            'userMessage',
            contains('geofence'),
          ),
        ),
      );
    });

    test(
      'without a location provider the punch fails clearly and sends nothing',
      () async {
        final noGps = FirestoreEmployeeHomeRepository(
          firestore: db,
          functions: callables,
          now: fixedNow,
        );
        await expectLater(
          noGps.recordAttendanceAction(
            access: access,
            action: AttendanceAction.checkIn,
          ),
          throwsA(isA<AppException>()),
        );
        expect(callables.calls.map((call) => call.name), [
          'getAttendanceSelfiePolicy',
        ]);
      },
    );

    test('sends no GPS fix when organization policy disables it', () async {
      callables.attendancePolicy['requireGeolocation'] = false;
      final noGps = FirestoreEmployeeHomeRepository(
        firestore: db,
        functions: callables,
        now: fixedNow,
      );
      final policy = await noGps.getAttendancePolicy(access: access);

      await noGps.recordAttendanceAction(
        access: access,
        action: AttendanceAction.checkIn,
        policy: policy,
      );

      final punch = callables.calls.singleWhere(
        (call) => call.name == 'recordAttendancePunch',
      );
      expect(punch.payload, {'kind': 'checkIn', 'branchId': 'br-01'});
    });

    test('an employee without a single active branch cannot punch', () async {
      final ambiguous = UserAccessContext(
        user: access.user,
        organization: acmeOrg,
        assignedBranches: [acmeBranch('br-01'), acmeBranch('br-02')],
      );
      await expectLater(
        repo.recordAttendanceAction(
          access: ambiguous,
          action: AttendanceAction.checkIn,
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
      expect(callables.calls, isEmpty);
    });
  });

  group('debug simulator', () {
    test('is exposed only by the mock repository', () {
      final real = EmployeeHomeController(repository: repo);
      final mock = EmployeeHomeController(
        repository: MockEmployeeHomeRepository(delay: Duration.zero),
      );
      addTearDown(real.dispose);
      addTearDown(mock.dispose);

      expect(real.simulator, isNull);
      expect(mock.simulator, isNotNull); // tests run in debug mode
    });

    test(
      'a production repository cannot be driven by the simulator call',
      () async {
        final controller = EmployeeHomeController(repository: repo);
        addTearDown(controller.dispose);
        await controller.loadHomeSummary(access: access);

        final applied = await controller.setSimulatedStatus(
          AttendanceStatus.checkedOut,
        );

        expect(applied, isFalse);
        expect(
          controller.summary?.currentStatus,
          AttendanceStatus.notCheckedIn,
        );
      },
    );
  });

  group('EmployeeHomeController action feedback', () {
    test('a failed punch reports false and exposes the error', () async {
      callables.failWith = const NetworkException();
      callables.failOnName = 'recordAttendancePunch';
      final controller = EmployeeHomeController(repository: repo);
      addTearDown(controller.dispose);
      await controller.loadHomeSummary(access: access);

      final recorded = await controller.performNextAttendanceAction();

      expect(recorded, isFalse);
      expect(controller.actionErrorMessage, isNotNull);
      expect(controller.summary, isNotNull); // list kept, not an error state
      expect(controller.hasError, isFalse);
    });

    test('a successful punch reports true', () async {
      final controller = EmployeeHomeController(repository: repo);
      addTearDown(controller.dispose);
      await controller.loadHomeSummary(access: access);

      expect(await controller.performNextAttendanceAction(), isTrue);
      expect(controller.actionErrorMessage, isNull);
    });
  });
}
