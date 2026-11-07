import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/features/attendance/data/firestore_attendance_repository.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_repository.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fixed_clock.dart';

final DateTime _today = BusinessTime.today(fixedNow);

/// Copies the mock's seeded entries into a fake Firestore so both
/// implementations answer the same questions over the same data.
Future<FakeFirebaseFirestore> _seededFirestore() async {
  final firestore = FakeFirebaseFirestore();
  final seed = MockAttendanceRepository(now: fixedNow);
  for (final day in [_today, _today.subtract(const Duration(days: 1))]) {
    final entries = await seed.getAttendance(
      access: orgAdminAccess(),
      date: day,
    );
    for (final e in entries) {
      await firestore.collection('attendance_entries').doc(e.id).set({
        'id': e.id,
        'organizationId': e.organizationId,
        'branchId': e.branchId,
        'employeeId': e.employeeId,
        'employeeName': e.employeeName,
        'workDate': Timestamp.fromDate(BusinessTime.startOfDay(e.workDate)),
        'workDateString': BusinessTime.keyOfDate(e.workDate),
        'status': e.status.name,
        'reviewStatus': e.reviewStatus.name,
        'checkInAt': e.checkInAt == null
            ? null
            : Timestamp.fromDate(e.checkInAt!),
        'checkOutAt': e.checkOutAt == null
            ? null
            : Timestamp.fromDate(e.checkOutAt!),
        'note': e.note,
        'kioskEntry': e.kioskEntry,
      });
    }
  }
  return firestore;
}

GroupAttendanceRequest _group(
  List<String> ids, {
  String branchId = 'br-01',
  AttendanceStatus status = AttendanceStatus.present,
}) => GroupAttendanceRequest(
  branchId: branchId,
  workDate: _today,
  checkInAt: fixedNow(),
  status: status,
  attendees: [
    for (final id in ids)
      GroupAttendanceAttendee(employeeId: id, employeeName: 'Name $id'),
  ],
);

void _contract(String name, Future<AttendanceRepository> Function() create) {
  group('AttendanceRepository contract: $name', () {
    late AttendanceRepository repo;
    setUp(() async => repo = await create());

    test('employee sees only their own entries', () async {
      final entries = await repo.getAttendance(
        access: employeeAccess(),
        date: _today,
      );
      expect(entries, isNotEmpty);
      expect(entries.every((e) => e.employeeId == 'user-emp-01'), isTrue);
    });

    test('employee cannot ask for a colleague', () {
      expect(
        () => repo.getAttendance(
          access: employeeAccess(),
          date: _today,
          employeeId: 'user-emp-02',
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('branch manager is limited to the active assigned branch', () async {
      final entries = await repo.getAttendance(
        access: branchManagerAccess(),
        date: _today,
        activeBranchId: 'br-01',
      );
      expect(entries, isNotEmpty);
      expect(entries.every((e) => e.branchId == 'br-01'), isTrue);
    });

    test('branch manager cannot read an unassigned branch', () {
      expect(
        () => repo.getAttendance(
          access: branchManagerAccess(branchIds: ['br-01']),
          date: _today,
          activeBranchId: 'br-02',
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('org admin sees the whole organization for the day', () async {
      final entries = await repo.getAttendance(
        access: orgAdminAccess(),
        date: _today,
      );
      expect(
        entries.map((e) => e.branchId).toSet(),
        containsAll(['br-01', 'br-02']),
      );
    });

    test('org admin of another organization sees nothing', () async {
      final entries = await repo.getAttendance(
        access: orgAdminAccess(org: otherOrg, branchIds: const []),
        date: _today,
      );
      expect(entries, isEmpty);
    });

    test('platform users have no attendance scope', () {
      expect(
        () => repo.getAttendance(access: platformAccess(), date: _today),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('review requires scope: wrong branch, employee, platform', () async {
      final manager = branchManagerAccess();
      expect(
        () => repo.reviewException(
          access: manager,
          entryId: 'att-05', // br-02 entry
          activeBranchId: 'br-01',
          decision: AttendanceReviewDecision.verify,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(
        () => repo.reviewException(
          access: employeeAccess(),
          entryId: 'att-02',
          activeBranchId: 'br-01',
          decision: AttendanceReviewDecision.verify,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(
        () => repo.reviewException(
          access: platformAccess(),
          entryId: 'att-02',
          activeBranchId: 'br-01',
          decision: AttendanceReviewDecision.verify,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('branch manager verifies an exception in their branch', () async {
      final updated = await repo.reviewException(
        access: branchManagerAccess(),
        entryId: 'att-02',
        activeBranchId: 'br-01',
        decision: AttendanceReviewDecision.verify,
      );
      expect(updated.reviewStatus, AttendanceReviewStatus.verified);
    });

    test(
      'group check-in records employees and shows them afterwards',
      () async {
        final access = branchManagerAccess();
        final recorded = await repo.markGroupAttendance(
          access: access,
          request: _group([
            'user-emp-20',
            'user-emp-21',
          ], status: AttendanceStatus.late),
        );
        expect(recorded, hasLength(2));
        expect(
          recorded.every((e) => e.status == AttendanceStatus.late),
          isTrue,
        );

        final entries = await repo.getAttendance(
          access: access,
          date: _today,
          activeBranchId: 'br-01',
        );
        expect(
          entries.map((e) => e.employeeId),
          containsAll(['user-emp-20', 'user-emp-21']),
        );
      },
    );

    test('the same employee is never recorded twice on a day', () async {
      final access = branchManagerAccess();
      await repo.markGroupAttendance(
        access: access,
        request: _group(['user-emp-30']),
      );
      expect(
        () => repo.markGroupAttendance(
          access: access,
          request: _group(['user-emp-30']),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test(
      'an employee already checked in (late status included) is rejected',
      () {
        // user-emp-02 has a late entry in br-01 today (seeded).
        expect(
          () => repo.markGroupAttendance(
            access: branchManagerAccess(),
            request: _group(['user-emp-02']),
          ),
          throwsA(isA<AppException>()),
        );
      },
    );

    test('group check-in is limited to managers of the branch', () {
      expect(
        () => repo.markGroupAttendance(
          access: employeeAccess(),
          request: _group(['user-emp-40']),
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(
        () => repo.markGroupAttendance(
          access: branchManagerAccess(branchIds: ['br-01']),
          request: _group(['user-emp-40'], branchId: 'br-02'),
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });
  });
}

void main() {
  _contract('mock', () async => MockAttendanceRepository(now: fixedNow));

  _contract(
    'Firestore (fake)',
    () async => FirestoreAttendanceRepository(
      firestore: await _seededFirestore(),
      now: fixedNow,
    ),
  );
}
