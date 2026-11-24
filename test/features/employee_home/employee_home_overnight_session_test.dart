import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart'
    show CheckoutStatus;
import 'package:workaxis/features/employee_home/data/employee_session_day_reader.dart';
import 'package:workaxis/features/employee_home/data/firestore_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/models/device_location.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/location_peek.dart';
import 'package:workaxis/features/employee_home/domain/services/attendance_location_provider.dart';

import '../../helpers/access_fixtures.dart';

class _Callables implements CallableFunctions {
  final List<({String name, Map<String, dynamic> payload})> calls = [];

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> payload = const {},
  ]) async {
    calls.add((name: name, payload: payload));
    if (name == FirestoreEmployeeHomeRepository.attendancePolicyCallable) {
      return {'requireAttendanceSelfie': false, 'requireGeolocation': false};
    }
    return const {};
  }
}

class _NoLocation implements AttendanceLocationProvider {
  @override
  Future<DeviceLocation> currentLocation() async =>
      const DeviceLocation(latitude: 0, longitude: 0, accuracyMeters: 5);

  @override
  Future<LocationPeek> peekLocation() async =>
      const LocationPeek(LocationReadiness.unavailable);
}

/// 02:00 IST on Nov 7, three hours after a 21:00 IST Nov 6 night shift start.
final DateTime _afterMidnight = DateTime.utc(2026, 11, 6, 20, 30);

Timestamp _utc(int day, int hour, [int minute = 0]) =>
    Timestamp.fromDate(DateTime.utc(2026, 11, day, hour, minute));

Future<void> _nightShift(
  FakeFirebaseFirestore db, {
  String id = 'night-open',
  String branchId = 'br-02',
  Map<String, dynamic> extra = const {'open': true},
}) => db.collection('attendance_entries').doc(id).set({
  'organizationId': 'org-acme',
  'branchId': branchId,
  'employeeId': 'user-emp-01',
  'employeeName': 'Sarah Connor',
  'workDateString': '2026-11-06',
  'status': 'present',
  'checkInAt': _utc(6, 15, 30), // 21:00 IST
  'scheduledStartAt': _utc(6, 15, 30),
  'scheduledEndAt': _utc(6, 23, 30), // 05:00 IST
  'checkoutReminderAt': _utc(6, 23, 45),
  'checkoutOverdueAt': _utc(7, 1, 30),
  ...extra,
});

void main() {
  late FakeFirebaseFirestore db;
  late _Callables callables;
  late FirestoreEmployeeHomeRepository repo;

  final twoBranches = employeeAccess().copyWith(
    assignedBranches: [acmeBranch('br-01'), acmeBranch('br-02')],
    activeBranch: ActiveBranchContext.fromBranch(acmeBranch('br-01')),
  );

  setUp(() {
    db = FakeFirebaseFirestore();
    callables = _Callables();
    repo = FirestoreEmployeeHomeRepository(
      firestore: db,
      functions: callables,
      locationProvider: _NoLocation(),
      now: () => _afterMidnight,
    );
  });

  group('open session after midnight', () {
    test(
      'a night shift started yesterday is the active session with its branch',
      () async {
        await _nightShift(db);

        final summary = await repo.getEmployeeHomeSummary(access: twoBranches);

        expect(summary.currentStatus, AttendanceStatus.checkedIn);
        expect(summary.branchId, 'br-02');
        expect(summary.workingDuration, '5h 00m'); // 15:30Z -> 20:30Z
        expect(summary.session?.isRunning, isTrue);
        expect(summary.attendanceEntry?.id, 'night-open');
        expect(summary.attendanceEntry?.workDate, DateTime(2026, 11, 6));
      },
    );

    test('earlier sessions of the same shift day count as worked', () async {
      await _nightShift(db);
      await _nightShift(
        db,
        id: 'evening-done',
        extra: {
          'open': false,
          'checkInAt': _utc(6, 12, 30),
          'checkOutAt': _utc(6, 13, 30),
        },
      );

      final summary = await repo.getEmployeeHomeSummary(access: twoBranches);

      expect(summary.currentStatus, AttendanceStatus.checkedIn);
      expect(summary.workingDuration, '6h 00m');
    });

    test('check-out after midnight targets the open session branch', () async {
      await _nightShift(db);
      final onSessionBranch = twoBranches.copyWith(
        activeBranch: ActiveBranchContext.fromBranch(acmeBranch('br-02')),
      );

      await repo.recordAttendanceAction(
        access: onSessionBranch,
        action: AttendanceAction.checkOut,
      );

      final punch = callables.calls.singleWhere(
        (call) => call.name == FirestoreEmployeeHomeRepository.punchCallable,
      );
      expect(punch.payload, {'kind': 'checkOut', 'branchId': 'br-02'});
    });

    test(
      'an employee on another branch is told to switch back to the session',
      () async {
        await _nightShift(db);

        await expectLater(
          repo.recordAttendanceAction(
            access: twoBranches,
            action: AttendanceAction.checkOut,
          ),
          throwsA(isA<BranchAuthorizationException>()),
        );
        expect(
          callables.calls.map((call) => call.name),
          isNot(contains(FirestoreEmployeeHomeRepository.punchCallable)),
        );
      },
    );

    test(
      'a session the system closed is not open and counts no time',
      () async {
        final now = DateTime.utc(2026, 11, 7, 9); // 14:30 IST
        final closedRepo = FirestoreEmployeeHomeRepository(
          firestore: db,
          functions: callables,
          locationProvider: _NoLocation(),
          now: () => now,
        );
        await db.collection('attendance_entries').doc('closed').set({
          'employeeId': 'user-emp-01',
          'branchId': 'br-01',
          'workDateString': '2026-11-07',
          'checkInAt': _utc(7, 3),
          'open': false,
          'checkoutStatus': 'missing',
          'sessionClosure': {'closedAt': _utc(7, 8, 30)},
        });

        final summary = await closedRepo.getEmployeeHomeSummary(
          access: employeeAccess(),
        );

        expect(summary.currentStatus, AttendanceStatus.checkedOut);
        expect(summary.checkOutNote, 'Check-out missing');
        expect(summary.workingDuration, '0h 00m');
        expect(summary.session, isNull);
        expect(summary.attendanceEntry?.checkoutStatus, CheckoutStatus.missing);
      },
    );
  });

  group('EmployeeSessionDayReader', () {
    EmployeeSessionDayReader reader(DateTime now) =>
        EmployeeSessionDayReader(firestore: () => db, now: () => now);

    test('uses the open session\'s shift day, else today', () async {
      await _nightShift(db);

      final overnight = await reader(_afterMidnight).read('user-emp-01');
      expect(overnight.dayKey, '2026-11-06');
      expect(overnight.openEntry?.id, 'night-open');

      await db.collection('attendance_entries').doc('night-open').update({
        'open': false,
        'checkOutAt': _utc(6, 23, 40),
      });
      final afterCheckOut = await reader(_afterMidnight).read('user-emp-01');
      expect(afterCheckOut.dayKey, '2026-11-07');
      expect(afterCheckOut.openEntry, isNull);
      expect(afterCheckOut.entries, isEmpty);
    });

    test('never reads a colleague\'s open session', () async {
      await db.collection('attendance_entries').doc('other').set({
        'employeeId': 'someone-else',
        'workDateString': '2026-11-06',
        'checkInAt': _utc(6, 15),
        'open': true,
      });

      final day = await reader(_afterMidnight).read('user-emp-01');

      expect(day.openEntry, isNull);
      expect(day.entries, isEmpty);
    });

    test('SessionDayEntry.isOpen honours the flag and legacy documents', () {
      final checkedIn = {'checkInAt': _utc(7, 3)};
      expect(SessionDayEntry('a', {...checkedIn, 'open': true}).isOpen, isTrue);
      expect(
        SessionDayEntry('b', {...checkedIn, 'open': false}).isOpen,
        isFalse,
      );
      expect(SessionDayEntry('c', checkedIn).isOpen, isTrue);
      expect(
        SessionDayEntry('d', {
          ...checkedIn,
          'sessionClosure': {'closedAt': _utc(7, 19)},
        }).isOpen,
        isFalse,
      );
      expect(
        SessionDayEntry('e', {
          ...checkedIn,
          'open': true,
          'checkOutAt': _utc(7, 9),
        }).isOpen,
        isFalse,
      );
    });
  });
}
