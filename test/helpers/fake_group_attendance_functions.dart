import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/time/business_time.dart';

/// Callable boundary fake. Server membership rules have independent TS tests.
class FakeGroupAttendanceFunctions implements CallableFunctions {
  FakeGroupAttendanceFunctions(
    this.firestore, {
    this.organizationId = 'org-acme',
    this.actorId = 'user-bm-01',
    this.employeeNames = const {},
  });

  final FirebaseFirestore firestore;
  final String organizationId;
  final String actorId;
  final Map<String, String> employeeNames;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> payload = const {},
  ]) async {
    if (name != 'recordGroupAttendance') {
      throw StateError('Unexpected callable $name');
    }
    calls.add(Map.of(payload));
    final ids = List<String>.from(payload['employeeIds'] as List);
    final key = payload['workDate'] as String;
    final date = DateTime.parse(key);
    final entryIds = [for (final uid in ids) '${uid}_$key'];
    final all = await firestore
        .collection('attendance_entries')
        .where('workDateString', isEqualTo: key)
        .get();
    if (ids.toSet().length != ids.length ||
        all.docs.any((doc) => ids.contains(doc.data()['employeeId']))) {
      throw const DatabaseException('Already recorded.');
    }
    final batch = firestore.batch();
    for (var i = 0; i < ids.length; i++) {
      batch.set(firestore.collection('attendance_entries').doc(entryIds[i]), {
        'id': entryIds[i],
        'organizationId': organizationId,
        'branchId': payload['branchId'],
        'employeeId': ids[i],
        'employeeName': employeeNames[ids[i]] ?? 'Name ${ids[i]}',
        'workDate': Timestamp.fromDate(BusinessTime.startOfDay(date)),
        'workDateString': key,
        'status': payload['status'],
        'reviewStatus': 'none',
        'checkInAt': Timestamp.fromDate(
          DateTime.parse(payload['checkInAt'] as String),
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'manager-group',
        'shiftName': payload['shiftName'],
        'note': payload['note'],
        'kioskEntry': false,
      });
    }
    batch.set(
      firestore
          .collection('group_attendance_batches')
          .doc(payload['requestId'] as String),
      {
        'createdById': actorId,
        'organizationId': organizationId,
        'branchId': payload['branchId'],
        'workDate': key,
        'attendeeCount': ids.length,
        'shiftName': payload['shiftName'],
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
    return {'entryIds': entryIds};
  }
}
