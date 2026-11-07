import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employee_home/data/firestore_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/data/mock_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/models/device_location.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/services/attendance_location_provider.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fixed_clock.dart';

class _FakeCallables implements CallableFunctions {
  final List<({String name, Map<String, dynamic> payload})> calls = [];
  Object? failWith;
  VoidCallback? onCall;

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> payload = const {},
  ]) async {
    calls.add((name: name, payload: payload));
    if (failWith != null) throw failWith!;
    onCall?.call();
    return const {};
  }
}

typedef VoidCallback = void Function();

class _FixedLocation implements AttendanceLocationProvider {
  @override
  Future<DeviceLocation> currentLocation() async => const DeviceLocation(
    latitude: 12.9716,
    longitude: 77.5946,
    accuracyMeters: 8,
  );
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

        final call = callables.calls.single;
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
        expect(callables.calls.last.payload['kind'], kind);
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
        expect(callables.calls, isEmpty);
      },
    );

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
