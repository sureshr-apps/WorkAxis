import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/features/attendance/data/attendance_entry_mapper.dart';
import 'package:workaxis/features/attendance/data/firestore_attendance_repository.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fixed_clock.dart';
import '../../helpers/fake_group_attendance_functions.dart';

/// Pins the documents the repository writes to what `firestore.rules`
/// accept: server timestamps, the `manager-group` source, only allowed
/// fields, and business-timezone day keys.
void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreAttendanceRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreAttendanceRepository(
      firestore: firestore,
      functions: FakeGroupAttendanceFunctions(
        firestore,
        organizationId: 'org-acme',
        employeeNames: const {
          'emp-101': 'Alice Worker',
          'emp-102': 'Bob Builder',
        },
      ),
      now: fixedNow,
    );
  });

  GroupAttendanceRequest request({
    DateTime? workDate,
    AttendanceStatus status = AttendanceStatus.present,
    List<String> ids = const ['emp-1', 'emp-2'],
  }) => GroupAttendanceRequest(
    branchId: 'br-01',
    workDate: workDate ?? BusinessTime.today(fixedNow),
    checkInAt: BusinessTime.startOfDay(workDate ?? BusinessTime.today(fixedNow))
        .add(const Duration(hours: 8)),
    status: status,
    note: 'Bus arrival',
    attendees: [
      for (final id in ids)
        GroupAttendanceAttendee(employeeId: id, employeeName: 'Name $id'),
    ],
  );

  // Fields allowed by `isValidManagerEntry` in firestore.rules.
  const allowedEntryFields = {
    'id',
    'organizationId',
    'branchId',
    'employeeId',
    'employeeName',
    'workDate',
    'workDateString',
    'status',
    'reviewStatus',
    'checkInAt',
    'shiftName',
    'note',
    'kioskEntry',
    'source',
    'createdAt',
  };

  test('trusted callable preserves validated effective time and server audit fields', () async {
    final recorded = await repo.markGroupAttendance(
      access: branchManagerAccess(),
      request: request(),
    );

    expect(recorded.first.id, 'emp-1_2026-11-07');
    final doc = await firestore
        .collection('attendance_entries')
        .doc('emp-1_2026-11-07')
        .get();
    final data = doc.data()!;
    expect(data.keys.toSet().difference(allowedEntryFields), isEmpty);
    expect(data['source'], 'manager-group');
    expect(data['workDateString'], '2026-11-07');
    expect(data['organizationId'], 'org-acme');
    // The fake resolves FieldValue.serverTimestamp(); a device value of 2020
    // would mean the client time leaked through.
    expect(
      (data['checkInAt'] as Timestamp).toDate().toUtc(),
      request().checkInAt,
    );
    expect(data['createdAt'], isA<Timestamp>());
    // workDate is the start of the business day (IST midnight).
    expect(
      (data['workDate'] as Timestamp).toDate().toUtc(),
      DateTime.utc(2026, 11, 6, 18, 30),
    );
  });

  test('the audit batch record matches the rule schema', () async {
    await repo.markGroupAttendance(
      access: branchManagerAccess(),
      request: request(),
    );
    final batches = await firestore
        .collection('group_attendance_batches')
        .get();
    final data = batches.docs.single.data();
    expect(data['createdById'], 'user-bm-01');
    expect(data['workDate'], '2026-11-07');
    expect(data['attendeeCount'], 2);
    expect(data['createdAt'], isA<Timestamp>());
  });

  test('review writes server time and the reviewer identity', () async {
    await firestore.collection('attendance_entries').doc('e1').set({
      'organizationId': 'org-acme',
      'branchId': 'br-01',
      'employeeId': 'emp-1',
      'workDateString': '2026-11-07',
      'status': 'late',
      'reviewStatus': 'needsReview',
    });
    await repo.reviewException(
      access: branchManagerAccess(),
      entryId: 'e1',
      activeBranchId: 'br-01',
      decision: AttendanceReviewDecision.dismiss,
    );
    final data =
        (await firestore.collection('attendance_entries').doc('e1').get())
            .data()!;
    expect(data['reviewStatus'], 'dismissed');
    expect(data['reviewedById'], 'user-bm-01');
    expect(data['reviewedAt'], isA<Timestamp>());
  });

  test('review of an entry in another organization is denied', () async {
    await firestore.collection('attendance_entries').doc('foreign').set({
      'organizationId': 'org-other',
      'branchId': 'br-01',
      'employeeId': 'emp-9',
      'workDateString': '2026-11-07',
      'status': 'late',
    });
    expect(
      () => repo.reviewException(
        access: orgAdminAccess(),
        entryId: 'foreign',
        activeBranchId: 'br-01',
        decision: AttendanceReviewDecision.verify,
      ),
      throwsA(isA<AccessDeniedException>()),
    );
  });

  test(
    'users without an organization are rejected, never "org-platform"',
    () async {
      expect(
        () => repo.markGroupAttendance(
          access: platformAccess(),
          request: request(),
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      final entries = await firestore.collection('attendance_entries').get();
      expect(entries.docs, isEmpty);
    },
  );

  test('absent/incomplete cannot be recorded as a group check-in', () {
    expect(
      () => repo.markGroupAttendance(
        access: branchManagerAccess(),
        request: request(status: AttendanceStatus.absent),
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('dates in the future or beyond the backdate window are rejected', () {
    final today = BusinessTime.today(fixedNow);
    expect(
      () => repo.markGroupAttendance(
        access: branchManagerAccess(),
        request: request(workDate: today.add(const Duration(days: 1))),
      ),
      throwsA(isA<DatabaseException>()),
    );
    expect(
      () => repo.markGroupAttendance(
        access: branchManagerAccess(),
        request: request(workDate: today.subtract(const Duration(days: 7))),
      ),
      throwsA(isA<DatabaseException>()),
    );
    // six days back is still allowed
    expect(
      repo.markGroupAttendance(
        access: branchManagerAccess(),
        request: request(workDate: today.subtract(const Duration(days: 6))),
      ),
      completion(hasLength(2)),
    );
  });

  test('group check-in respects the attendee cap', () {
    final ids = [for (var i = 0; i < 401; i++) 'emp-$i'];
    expect(
      () => repo.markGroupAttendance(
        access: branchManagerAccess(),
        request: request(ids: ids),
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('workDate comes from the business day key, not the device zone', () {
    // 2026-11-06 20:00 UTC is already 2026-11-07 01:30 in Asia/Kolkata.
    final lateEvening = DateTime.utc(2026, 11, 6, 20);
    expect(BusinessTime.keyOfInstant(lateEvening), '2026-11-07');
    expect(BusinessTime.dateOf(lateEvening), DateTime(2026, 11, 7));

    final entry = AttendanceEntryMapper.fromData('e', {
      'workDate': Timestamp.fromDate(DateTime.utc(2026, 11, 6, 18, 30)),
      'status': 'present',
    });
    expect(entry.workDate, DateTime(2026, 11, 7));

    final byKey = AttendanceEntryMapper.fromData('e', {
      'workDateString': '2026-11-07',
      'workDate': Timestamp.fromDate(DateTime.utc(2000)),
    });
    expect(byKey.workDate, DateTime(2026, 11, 7));
  });

  test('unknown statuses are flagged, not reported as present', () {
    final entry = AttendanceEntryMapper.fromData('e', {
      'workDateString': '2026-11-07',
      'status': 'mystery',
    });
    expect(entry.status, AttendanceStatus.incomplete);
  });
}
