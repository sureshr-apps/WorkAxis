import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/attendance/data/firestore_attendance_repository.dart';

import '../../helpers/access_fixtures.dart';

void main() {
  test(
    'attendance reads past 500 records without omissions or duplicates',
    () async {
      final firestore = FakeFirebaseFirestore();
      for (var i = 0; i < 501; i++) {
        await firestore.collection('attendance_entries').doc('entry-$i').set({
          'organizationId': 'org-acme',
          'branchId': 'br-01',
          'employeeId': 'emp-$i',
          'workDateString': '2026-11-07',
          'status': i == 500 ? 'late' : 'present',
        });
      }
      final repo = FirestoreAttendanceRepository(firestore: firestore);
      final entries = await repo.getAttendance(
        access: branchManagerAccess(),
        date: DateTime(2026, 11, 7),
        activeBranchId: 'br-01',
      );
      expect(entries, hasLength(501));
      expect(entries.map((e) => e.id).toSet(), hasLength(501));
      expect(entries.any((e) => e.employeeId == 'emp-500'), isTrue);
    },
  );
}
