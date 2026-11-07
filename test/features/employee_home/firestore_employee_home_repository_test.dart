import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/employee_home/data/firestore_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';

void main() {
  group('FirestoreEmployeeHomeRepository Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreEmployeeHomeRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreEmployeeHomeRepository(firestore: fakeFirestore);
    });

    test('getEmployeeHomeSummary returns expected default checked-in state', () async {
      final summary = await repository.getEmployeeHomeSummary();
      expect(summary.employeeName, equals('Alex Rivera'));
      expect(summary.currentStatus, equals(AttendanceStatus.checkedIn));
      expect(summary.branchName, equals('Downtown Flagship'));
      expect(summary.isWithinGeofence, isTrue);
    });

    test('recordAttendanceAction logs punch and updates current status', () async {
      final summary = await repository.recordAttendanceAction(AttendanceAction.startBreak);
      expect(summary.currentStatus, equals(AttendanceStatus.onBreak));

      // Check punch in Firestore
      final punches = await fakeFirestore.collection('attendance_punches').get();
      expect(punches.docs, hasLength(1));
      expect(punches.docs.first.data()['action'], equals('startBreak'));
    });

    test('setSimulatedStatus allows changing frontline simulator status', () async {
      final summary = await repository.setSimulatedStatus(AttendanceStatus.checkedOut);
      expect(summary.currentStatus, equals(AttendanceStatus.checkedOut));
      expect(summary.checkOutTime, equals('05:02 PM'));
    });
  });
}
